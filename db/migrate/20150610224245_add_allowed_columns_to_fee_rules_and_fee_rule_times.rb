class AddAllowedColumnsToFeeRulesAndFeeRuleTimes < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table fee_rules
        add column online_visit_allowed text default 'not_allowed' not null
          constraint online_visit_allowed_check
            check (online_visit_allowed =
            ANY (ARRAY['allowed','not_allowed']) ),
        add column office_visit_allowed text default 'not_allowed' not null
          constraint office_visit_allowed_check
            check (office_visit_allowed =
            ANY (ARRAY['allowed','not_allowed']) ),
        add column area_visit_allowed text default 'not_allowed' not null
          constraint area_visit_allowed_check
            check (area_visit_allowed =
            ANY (ARRAY['allowed','not_allowed']) ),
        add column online_visit_fee numeric(4,0) default 100 not null,
        add column office_visit_fee numeric(4,0) default 100 not null,
        add column area_visit_fee numeric(4,0) default 100 not null;


      alter table fee_rule_times
        add column online_visit_allowed text default 'not_allowed' not null
          constraint online_visit_allowed_check
            check (online_visit_allowed =
            ANY (ARRAY['allowed','not_allowed']) ),
        add column office_visit_allowed text default 'not_allowed' not null
          constraint office_visit_allowed_check
            check (office_visit_allowed =
            ANY (ARRAY['allowed','not_allowed']) ),
        add column area_visit_allowed text default 'not_allowed' not null
          constraint area_visit_allowed_check
            check (area_visit_allowed =
            ANY (ARRAY['allowed','not_allowed']) ),
        add column online_visit_fee numeric(4,0) default 100 not null,
        add column office_visit_fee numeric(4,0) default 100 not null,
        add column area_visit_fee numeric(4,0) default 100 not null;


      alter table free_times
        add column online_visit_allowed text default 'not_allowed' not null
          constraint online_visit_allowed_check
            check (online_visit_allowed =
            ANY (ARRAY['allowed','not_allowed']) ),
        add column office_visit_allowed text default 'not_allowed' not null
          constraint office_visit_allowed_check
            check (office_visit_allowed =
            ANY (ARRAY['allowed','not_allowed']) ),
        add column area_visit_allowed text default 'not_allowed' not null
          constraint area_visit_allowed_check
            check (area_visit_allowed =
            ANY (ARRAY['allowed','not_allowed']) ),
        add column online_visit_fee numeric(4,0) default 100 not null,
        add column office_visit_fee numeric(4,0) default 100 not null,
        add column area_visit_fee numeric(4,0) default 100 not null;

                SQL

      # Reload db/functions/umedoc_functions.pgsql, needs to be AFTER adding the columns above
      file_path = Rails.root + 'db/functions/umedoc_functions.pgsql'
      if File.exists?(file_path) and File.readable?(file_path)
        if File.size(file_path) > 1000000
          puts "File size > 1000000, may cause slow performance when being loaded"
        end
        code_file = File.read(file_path)
        execute code_file
      else
        puts "No readable file found to load postgres functions"
      end
  end

  def down
    execute  <<-SQL
      alter table fee_rules
        drop column if exists online_visit_allowed,
        drop column if exists office_visit_allowed,
        drop column if exists area_visit_allowed,
        drop column if exists online_visit_fee,
        drop column if exists office_visit_fee,
        drop column if exists area_visit_fee;

      alter table fee_rule_times
        drop column if exists online_visit_allowed,
        drop column if exists office_visit_allowed,
        drop column if exists area_visit_allowed,
        drop column if exists online_visit_fee,
        drop column if exists office_visit_fee,
        drop column if exists area_visit_fee;

      alter table free_times
        drop column if exists online_visit_allowed,
        drop column if exists office_visit_allowed,
        drop column if exists area_visit_allowed,
        drop column if exists online_visit_fee,
        drop column if exists office_visit_fee,
        drop column if exists area_visit_fee;
                SQL

      #NB the down migration does NOT reverse the loading of db/functions/umedoc_functions
      puts "This down migration does NOT reverse the loading of db/functions/umedoc_functions"
  end
end
