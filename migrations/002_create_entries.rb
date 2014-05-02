Sequel.migration do
  up do
    create_table(:entries) do
      primary_key :id

      String :body
      String :subject
      String :author
      foreign_key :user_id, :users
    end
  end

  down do
    drop_table(:entries)
  end
end