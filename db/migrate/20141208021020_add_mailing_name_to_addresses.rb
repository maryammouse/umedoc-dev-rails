class AddMailingNameToAddresses < ActiveRecord::Migration
  def change
    add_column :addresses, :mailing_name, :string
  end
end
