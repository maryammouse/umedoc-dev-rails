class ChangeStatesCountryIsoToCountryId < ActiveRecord::Migration
  def change
    rename_column :states, :country_iso, :country_id
  end
end
