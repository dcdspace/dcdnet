class User < Sequel::Model

  one_to_many :entries
  one_to_many :comments

  def friends
    Friend.where(:initiator_user_id => self.id, :confirmed => 1).or(:initiator_user_id => self.id, :confirmed => 1)
  end

  def unconfirmed_friends

  end

end