class User < ActiveRecord::Base
	validates :name, length: { maximum: 128 }
end
