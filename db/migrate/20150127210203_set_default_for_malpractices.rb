class SetDefaultForMalpractices < ActiveRecord::Migration
  def up
    execute " ALTER TABLE malpractices
              ALTER COLUMN telemedicine SET DEFAULT true,
              ALTER COLUMN in_person SET DEFAULT false
    "
  end

  def down
    execute " ALTER TABLE malpractices
              ALTER COLUMN telemedicine DROP DEFAULT,
              ALTEr coLUMN in_person DROP DEFAULT
    "
  end
end
