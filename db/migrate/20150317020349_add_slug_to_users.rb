class AddSlugToUsers < ActiveRecord::Migration
  def up
    execute " ALTER TABLE users
              ADD COLUMN slug text;

              -- CREATE UNIQUE INDEX usr_slug_idx ON users (slug);
    "
  end
  def down
    execute " ALTER TABLE users
              DROP COLUMN slug;

              DROP INDEX IF EXISTS usr_slug_idx;

    "
  end
end
