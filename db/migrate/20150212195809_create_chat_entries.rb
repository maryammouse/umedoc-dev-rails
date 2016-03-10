class CreateChatEntries < ActiveRecord::Migration
  def up
    execute " CREATE TABLE chat_entries(
              id serial primary key,
              body text not null,
              connectionId varchar(255) not null,
              session_id varchar(255) not null REFERENCES visits(session_id)
    )"
  end

  def down
    execute " DROP TABLE chat_entries"
  end
end
