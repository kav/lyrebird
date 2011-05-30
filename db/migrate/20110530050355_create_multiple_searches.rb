class CreateMultipleSearches < ActiveRecord::Migration
  def self.up
    create_table :searches do |t|
      t.integer :user_id
      t.string :text, :last_tweet
      
      t.timestamps
    end
    
    User.all.each do |user|
      if !user.search.blank? then
        user.searches.create(:text => user.search, :last_tweet => user.last_tweet.to_s)
      end
    end
    
    remove_column :users, :search
    remove_column :users, :last_tweet
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, "Can't go back to one search per user"    
  end
end
