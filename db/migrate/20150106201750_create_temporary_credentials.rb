class CreateTemporaryCredentials < ActiveRecord::Migration
  def up
    execute " CREATE TABLE temporary_credentials (
              username varchar(255) not null references users(username),
              doctor_id integer not null references doctors(id),
              medical_license_number varchar(255) not null,
              state_medical_board_name varchar(255) not null references state_medical_boards(name),
              specialty_name varchar(64) not null references specialties(name),
              services varchar(50) not null
    )"
  end

  def down
    execute " DROP TABLE temporary_credentials"
  end
end
