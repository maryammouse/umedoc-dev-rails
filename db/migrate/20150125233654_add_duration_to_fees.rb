class AddDurationToFees < ActiveRecord::Migration
  def change
    add_column :fees, :duration, :interval, null:false, default:'30 minutes'
  end
end
