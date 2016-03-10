class RemoveZipCodeFromPrimaryCities < ActiveRecord::Migration
  def change
    remove_column :primary_cities, :zip_code, :string
  end
end
