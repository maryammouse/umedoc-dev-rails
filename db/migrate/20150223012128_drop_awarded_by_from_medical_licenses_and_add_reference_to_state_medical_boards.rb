class DropAwardedByFromMedicalLicensesAndAddReferenceToStateMedicalBoards < ActiveRecord::Migration
  def up
    execute  <<-SQL

      delete from medical_licenses;
      alter table medical_licenses
        drop column if exists awarded_by,
        add column state_medical_board_id integer not null references state_medical_boards(id);

                SQL
  end

  def down
    execute  <<-SQL
      alter table medical_licenses
        drop column if exists state_medical_board_id
        add column awarded_by text not null;
                SQL
  end

end
