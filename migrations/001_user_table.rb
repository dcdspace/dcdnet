Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id
#BASIC INFO
      String :email
      String :name
      Integer :age
      Date :birthday
#CONTACT INFO
      String :address
      String :city
      String :state
      String :country
#SCHOOL INFO
      String :school
      String :grade
#PICTURE URL
      String :picture

    end
  end

  down do
    drop_table(:users)
  end
end