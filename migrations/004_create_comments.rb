Sequel.migration do
  up do
    create_table(:comments) do
      primary_key :id

      String :body
      DateTime :created_at
      foreign_key :user_id, :users
      foreign_key :entry_id, :entries
    end
  end

  down do
    drop_table(:comments)
  end
end