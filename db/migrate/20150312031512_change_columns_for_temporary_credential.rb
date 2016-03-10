class ChangeColumnsForTemporaryCredential < ActiveRecord::Migration
  def up
    execute " ALTER TABLE temporary_credentials
              DROP COLUMN awarded_by,
              ADD COLUMN state_medical_board_id integer REFERENCES state_medical_boards(id)
    "
  end
  def down
    execute " ALTER TABLE temporary_credentials
              DROP COLUMN state_medical_board_id,
              ADD COLUMN awarded_by varchar(255) REFERENCES state_medical_boards(name)
    "
  end
end
