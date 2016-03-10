class AddCredentialCodeToCredentialTypes < ActiveRecord::Migration
  def change
    add_column :credential_types, :credential_code, :string
  end
end
