class RemoveColumnsFromUser < ActiveRecord::Migration
  def change
    remove_column :users, :email
    remove_column :users, :cellnumber
  end
end
