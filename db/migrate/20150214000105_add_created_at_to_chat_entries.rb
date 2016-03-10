class AddCreatedAtToChatEntries < ActiveRecord::Migration
  def up
    execute " ALTER TABLE chat_entries
              ADD COLUMN created_at timestamp NOT NULL
    "
  end

  def down
    execute " ALTER TABLE chat_entries
              DROP COLUMN created_at
    "
  end
end
