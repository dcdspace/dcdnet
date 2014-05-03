require 'sequel'
require 'sinatra'
require 'omniauth'
require 'google/omniauth'
require 'google/api_client/client_secrets'
if development?
set :port, 9292
end
#DATABASE INITIALIZATION
use Rack::ShowExceptions
DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://db/orm_demo.db')
require './models/entry.rb'
require './models/user.rb'
require './models/friend.rb'
require './models/comment.rb'



#GOOGLE AUTH

CLIENT_SECRETS = Google::APIClient::ClientSecrets.load

def client
  c = (Thread.current[:client] ||=
      Google::APIClient.new(:application_name => 'Ruby Google+ sample',
                            :application_version => '1.0.0'))
  # It's really important to clear these out,
  # since we reuse client objects across requests
  # for caching and performance reasons.
  c.authorization.clear_credentials!
  return c
end
client1 = Google::APIClient.new
oauth2 = client1.discovered_api('oauth2')


def api_client; settings.api_client; end

#LOGOUT CODE (CLEAR SESSIONS)
get '/logout' do
  session['credentials'] = nil
  session.clear
  redirect '/'
end

#POST CALLBACKS FOR FRIENDING OPERATIONS (SELF EXPLANATORY WHAT EACH DOES)
post '/friend' do
  if session['credentials']
    user = User.first(:email => session['email'])
    friend_id = params[:friend_id]
    f = Friend.new
    f.initiator_user_id = user.id
    f.friend_user_id = friend_id
    f.confirmed = 0
    f.created_at = Time.now
    f.save
    #redirect '/'
    user.id.to_s
  else
    user.id.to_s
  end
  user.id.to_s
end

post '/acceptfriend' do
  if session['credentials']
    friendship = Friend.where(:id => params[:friend_id].to_i, :confirmed => 0).first
    friendship.confirmed = 1
    friendship.save
    redirect '/profile/' + friendship.initiator_user_id.to_s
  else
    redirect '/'
  end

end

post '/unfriend' do
  if session['credentials']
    friendship = Friend.where(:id => params[:friend_id].to_i, :confirmed => 1).first
    friendship.delete
    redirect '/'
  else
    redirect '/'
  end

end

post '/cancelrequest' do
  if session['credentials']
    friendship = Friend.where(:id => params[:friend_id].to_i, :confirmed => 0).first
    friendship.delete
    redirect '/profile/' + friendship.initiator_user_id.to_s
  else
    redirect '/'
  end
end

# Support both GET and POST for callbacks. (AGAIN, MORE GOOGLE AUTH STUFF...)
%w(get post).each do |method|
  send(method, "/auth/:provider/callback") do
    Thread.current[:client] = env['omniauth.auth']['extra']['client']

    # Keep track of the tokens. Use a real database in production.
    session['uid'] = env['omniauth.auth']['uid']
    session['credentials'] = env['omniauth.auth']['credentials']


    redirect '/entries'
  end
end

get '/auth/failure' do
  redirect '/'
end

use Rack::Session::Cookie

use OmniAuth::Builder do
  provider OmniAuth::Strategies::Google,
           CLIENT_SECRETS.client_id,
           CLIENT_SECRETS.client_secret,
           :scope => [
               'https://www.googleapis.com/auth/userinfo.profile',
               'https://www.googleapis.com/auth/userinfo.email',
               'https://www.googleapis.com/auth/plus.me'
           ],
           :skip_info => false
end

#LOGIN

get '/login' do


  erb :login
end

post '/login' do
  username = params[:username]
  password = params[:password]


  session[:username] = username
end

#CREATE

get '/entry/create' do
  if session['credentials']
    user = User.first(:email => session['email'])
    @entry = Entry.new

    erb :create, :locals => {
        :user => user,
    }
  else
    redirect '/'
  end
end

post '/entry/create' do
  if session['credentials']
    user = User.first(:email => session['email'])
    entry = Entry.new
    entry.subject = params[:subject]
    entry.body = params[:body]
    entry.author = user.name
    entry.user_id = user.id
    entry.save


    redirect '/entries'
  else
    redirect '/'
  end
end

#READ

get '/entry/:id' do

end

get '/' do

  if session['credentials']
    redirect '/entries'

  else
    erb :login
  end
end

get '/entries' do

  if session['credentials']
    # Build an authorization object from the client secrets.
    authorization = CLIENT_SECRETS.to_authorization
    authorization.update_token!(
        :access_token => session['credentials']['access_token'],
        :refresh_token => session['credentials']['refresh_token']
    )
    @token = session['credentials']['access_token']



    result = client1.execute(
        :api_method => oauth2.userinfo.get,
        :authorization => authorization
    )
    puts result.status
    if result.status == 401
      # The access token expired, fetch a new one and retry once.
      redirect '/logout'
    end


    email = result.data.email
    @email = result.data.email
    session['email'] = email
    #CHECK IF USER EXISTS, AND REDIRECT TO EITHER PROFILE OR FIRST TIME SETUP PAGE
    @user = User.first(:email => email)
    user = User.first(:email => email)
    if @user
      @entries = Entry.where(:user_id => user.id).reverse
      @entries = @entries.all.reverse
      puts @entries.inspect
      @logged_in = true
      puts result.data.inspect
      @users = User.all.reverse
      user = User.first(:email => session['email'])
      @user_id = user.id
      redirect '/profile/' + @user_id.to_s

    else
      @logged_in = false
      user = User.new
      user.email = email
      user.name = result.data.name
      user.picture = result.data.picture
      user.save
      erb :firsttime, :locals => {
          :user => user,
      }
    end
  else

    content_type 'text/plain'
    "Missing credentials."
    redirect '/'
  end


end
#PROFILE
get '/profile/:id' do
  if session['credentials']
    my_profile = false
    is_friends = false
    user = User.first(:id => params[:id])
    current_user = User.first(:email => session['email'])
    if params[:id] == 'me'
      redirect '/profile/' + current_user.id.to_s
    end
    if params[:id] == current_user.id.to_s
      my_profile = true
    else
      my_profile = false
    end
    if user
      @entries = Entry.where(:user_id => user.id).reverse
      @entries = @entries.all.reverse
      @users = User.all.reverse
      @friend_list = []
      @unconfirmed_list = []
      @my_friends = []
      @approval_list = []
      @friends = Friend.where(:initiator_user_id => user.id, :confirmed => 1).or(:friend_user_id => user.id, :confirmed => 1).all.reverse
      @current_friends = Friend.where(:initiator_user_id => current_user.id, :confirmed => 1).or(:friend_user_id => current_user.id, :confirmed => 1).all.reverse
      @friends_unconfirmed = Friend.where(:initiator_user_id => current_user.id, :confirmed => 0).all.reverse
      @friends_approval = Friend.where(:friend_user_id => current_user.id, :confirmed => 0).all.reverse
      @user = User.first(:id => params[:id])
      @friends.each do |friend|
        if friend.initiator_user_id == user.id
          name = User.first(:id => friend.friend_user_id)
          puts name.name
          @friend_list << name
        elsif friend.friend_user_id == user.id
          name = User.first(:id => friend.initiator_user_id)
          puts name.name
          @friend_list << name
        end
      end
      @current_friends.each do |friend|
        if friend.initiator_user_id == current_user.id
          name = User.first(:id => friend.friend_user_id)
          puts name.name
          @my_friends << name
        elsif friend.friend_user_id == current_user.id
          name = User.first(:id => friend.initiator_user_id)
          puts name.name
          @my_friends << name
        end
      end
      @friends_unconfirmed.each do |friend|
        if friend.initiator_user_id == current_user.id
          name = User.first(:id => friend.friend_user_id)
          puts name.name
          @unconfirmed_list << name
        elsif friend.friend_user_id == current_user.id
          name = User.first(:id => friend.initiator_user_id)
          puts name.name
          @unconfirmed_list << name
        end
      end
      @friends_approval.each do |friend|
        if friend.initiator_user_id == current_user.id
          name = User.first(:id => friend.friend_user_id)
          puts name.name
          @approval_list << name
        elsif friend.friend_user_id == current_user.id
          name = User.first(:id => friend.initiator_user_id)
          puts name.name
          @approval_list << name
        end
      end
      if @my_friends.include? user
        is_friends = true
      else
        is_friends = false
      end
      puts @friends.inspect
      @user_id = user.id
      erb :entries, :locals => {
          :entries => @entries,
          :current_user => current_user,
          :my_profile => my_profile,
          :is_friends => is_friends
      }
    else
      redirect '/'
    end
  else
    redirect '/'
  end
end

#FIRST TIME LOGIN

get '/firstlogin' do


  if @logged_in
    redirect '/'
  else
    erb :firsttime
  end
end
#FORM FOR UPDATING USER'S BIO
post '/bio' do
  current_user = User.first(:email => session['email'])
  current_user.age = params[:age]
  current_user.birthday = params[:bday]
  current_user.address = params[:address]
  current_user.city = params[:city]
  current_user.state = params[:state]
  current_user.school = params[:school]
  current_user.grade = params[:grade]
  current_user.save

  redirect '/profile/me'
end


#UPDATE

get '/entry/:id/update' do
  if session['credentials']
    @id = params[:id].to_i
    @realID = params[:realID].to_i
    @entry = Entry[@id]
    user = User.first(:email => session['email'])

    erb :edit, :locals => {
        :user => user,
    }
  else
    redirect '/'
  end
end

post '/entry/:id/update' do
  if session['credentials']
    entry = Entry.first(:id => params[:id].to_i)
    current_user = User.first(:email => session['email'])
    if entry.user == current_user
      entry.update(:subject => params[:subject], :body => params[:body])
    end
    redirect '/entries'
  else
    redirect '/'
  end
end


#DELETE

post '/entry/:id/delete' do
  if session['credentials']
    id = params[:id].to_i
    entry = Entry.where(:id => id).first
    current_user = User.first(:email => session['email'])
    if entry.user == current_user
      entry.comments_dataset.destroy
      entry.delete
    end
    entry.id.to_s
  else
  end
end

#COMMENTS

#CREATE

post '/entry/:entry_id/comment/create' do
  current_user = User.first(:email => session['email'])

  entry = Entry.first(:id => params[:entry_id])

  comment = Comment.new
  comment.entry = entry
  comment.body = h params[:body]
  comment.created_at = Time.now
  comment.user = current_user
  comment.save
  message = "'do you really want to delete this comment?'"
  #redirect "/profile/#{params[:friend_id].to_s}"

  '<li id="'+ comment.id.to_s+'" class="list-group-item">
  <div class="panel panel-info">
  <div class="panel-heading"><div class="panel-title"><a style="color: #dddfff; border-bottom: 1px dashed yellow;" href="/profile/'+ comment.user.id.to_s+'">'+ current_user.name+'</a></div> - '+ Time.now.to_s+'<span style="float: right" align="right" id="loadingDelete'+ comment.id.to_s+'"> </span></div>
  <div class="panel-body">
                        <div align="right" class="inline" style="float: right">
                          <button id="'+ comment.id.to_s+'" type="submit" class="btn btn-danger commentDelete"><span class="glyphicon glyphicon-trash"></span> Delete</button>

                          <input type="hidden" value="'+ params[:friend_id].to_s+'" name="friend_id">
                          <input class="entry_id" id="'+ params[:entry_id].to_s+'" type="hidden" value="<%= entry.id %>" name="entry_id">


</div>
                      <p>'+ comment.body+'</p>
  </div>
                          </div>
  </li>
'
end

#DELETE

post '/entry/:entry_id/comment/:id/delete' do
  comment = Comment.first(:id => params[:id].to_i)
  comment.delete
  comment.id.to_s

  #redirect "/profile/#{params[:friend_id].to_s}"

end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def confirmation_post(url)
    "<form method='post' action='' class='inline'>" +
        "<input type='submit' value='delete'>" +
        "</form>"
  end
end

