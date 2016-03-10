class AddIdToStateMedicalBoards < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table state_medical_boards
        drop constraint if exists medical_board_states_pkey cascade,
        add id serial primary key,
        add constraint name_unique_constraint unique (name);

                SQL
  end

  def down
    execute  <<-SQL
      alter table state_medical_boards
        drop constraint if exists name_unique_constraint cascade,
        drop column if exists id,
        add constraint medical_board_states_pkey unique (name);

                SQL
  end
end
