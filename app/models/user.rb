class User < ActiveRecord::Base
	has_many :microposts
	validates :name, length: { maximum: 128 }
end
