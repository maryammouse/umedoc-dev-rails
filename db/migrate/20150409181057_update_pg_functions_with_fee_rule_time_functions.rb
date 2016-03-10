class UpdatePgFunctionsWithFeeRuleTimeFunctions < ActiveRecord::Migration

  def up
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
    #raise ActiveRecord::IrreversibleMigration
  end

end
