class AlterFeesAddNotNulls < ActiveRecord::Migration
  def change
      change_column_null :fees, :day_of_week, false
      change_column_null :fees, :time_range, false
      change_column_null :fees, :fee, false
  end
end
