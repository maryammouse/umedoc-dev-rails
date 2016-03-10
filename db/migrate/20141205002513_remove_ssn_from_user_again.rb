class RemoveSsnFromUserAgain < ActiveRecord::Migration
  def change
    remove_column :users, :ssn
  end
end
