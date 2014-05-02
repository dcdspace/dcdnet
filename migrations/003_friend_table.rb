Sequel.migration do
  up do
    create_table(:friends) do
      primary_key :id
      foreign_key :initiator_user_id, :users
      foreign_key :friend_user_id, :users
      Integer :confirmed, :size=>1
      DateTime :created_at
    end
  end

  down do
    drop_table(:friends)
  end
end