class AddSpecialtyToMalpractices < ActiveRecord::Migration
  def change
    add_column :malpractices, :specialty, :string
  end
end
