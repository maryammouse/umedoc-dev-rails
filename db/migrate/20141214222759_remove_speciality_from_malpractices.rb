class RemoveSpecialityFromMalpractices < ActiveRecord::Migration
  def change
    remove_column :malpractices, :speciality
  end
end
