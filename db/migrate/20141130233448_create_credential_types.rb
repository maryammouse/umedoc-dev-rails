class CreateCredentialTypes < ActiveRecord::Migration
  def change
    create_table :credential_types do |t|
      t.string :credential_type
      t.boolean :awarded_by
      t.boolean :valid_location
      t.boolean :reference_number
      t.boolean :first_issued_date
      t.boolean :expiry_date

      t.timestamps
    end
  end
end
