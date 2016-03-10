class AddColumnsToStripeSellers < ActiveRecord::Migration
  def up
    execute  <<-SQL
      delete from stripe_sellers;
      alter table stripe_sellers
        drop column token;
      alter table stripe_sellers
        add column access_token text not null,
        add column scope text not null,
        add constraint scope_constraint check (scope = ANY(ARRAY['read_write','read_only'])),
        add column livemode text not null,
        add constraint livemode_constraint check (livemode = ANY(ARRAY['true','false'])),
        add column refresh_token text not null,
        add column stripe_user_id text not null,
        add column stripe_publishable_key text not null;


                SQL
  end

  def down
    execute  <<-SQL
    alter table stripe_sellers
      drop column if exists scope,
      drop column if exists livemode,
      drop column if exists refresh_token,
      drop column if exists stripe_user_id,
      drop column if exists stripe_publishable_key;

    alter table stripe_sellers
      rename column access_token to token;

                SQL
  end
end
