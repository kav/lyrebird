class User < ActiveRecord::Base
  validates :name, :access_token, :access_secret, :presence => true
  validates_uniqueness_of :name
end
