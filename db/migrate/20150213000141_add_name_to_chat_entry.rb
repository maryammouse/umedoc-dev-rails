class AddNameToChatEntry < ActiveRecord::Migration
  def up
    execute " ALTER TABLE chat_entries
              ADD COLUMN name varchar(255) not null
      "
  end

  def down
    execute " ALTER TABLE chat_entries
              DROP COLUMN name varchar(255) not null
        "
  end
end
