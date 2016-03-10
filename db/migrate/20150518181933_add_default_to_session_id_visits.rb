class AddDefaultToSessionIdVisits < ActiveRecord::Migration
  def up
    execute " CREATE SEQUENCE visits_session_id_seq;"
    execute "
              ALTER TABLE visits
              ALTER session_id TYPE text,
              ALTER session_id SET DEFAULT nextval('visits_session_id_seq');

              ALTER SEQUENCE visits_session_id_seq OWNED BY visits.session_id


    "
  end

  def down
    execute "ALTER TABLE visits
             ALTER COLUMN session_id TYPE varchar(255);
    "
  end
end
