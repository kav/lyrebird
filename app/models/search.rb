class Search < ActiveRecord::Base
  validates_presence_of :text, :user_id
  
  belongs_to :user
end
