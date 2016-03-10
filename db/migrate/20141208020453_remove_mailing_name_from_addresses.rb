class RemoveMailingNameFromAddresses < ActiveRecord::Migration
  def change
    remove_column :addresses, :mailing_name, :string
  end
end
