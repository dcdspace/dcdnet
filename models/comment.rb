class Comment < Sequel::Model
  many_to_one :entry
  many_to_one :user

end