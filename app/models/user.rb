class User < ActiveRecord::Base
  validates :name, :access_token, :access_secret, :presence => true
  validates_uniqueness_of :name
  validates_inclusion_of :paid, :in => [true, false]
end
