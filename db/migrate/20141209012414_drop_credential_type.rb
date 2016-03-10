class DropCredentialType < ActiveRecord::Migration
  def change
    drop_table :credential_types
  end
end
