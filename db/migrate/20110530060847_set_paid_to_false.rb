class SetPaidToFalse < ActiveRecord::Migration
  def self.up
    change_column_default :users, :paid, false
    User.all.each do | user |
      if user.paid == nil
        user.paid = false
        user.save
      end
    end
  end

  def self.down
  end
end
