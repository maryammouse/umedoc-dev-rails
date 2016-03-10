class DropCredential < ActiveRecord::Migration
  def change
    drop_table :credentials
  end
end
