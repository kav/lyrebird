class AddPaidToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :paid, :boolean
  end

  def self.down
    remove_column :users, :paid
  end
end
