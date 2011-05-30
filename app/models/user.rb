class User < ActiveRecord::Base
  validates_presence_of :name, :access_token, :access_secret
  validates_uniqueness_of :name
  
  has_many :searches
  validates_inclusion_of :paid, :in => [true, false]
end
