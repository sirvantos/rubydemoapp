class User < ActiveRecord::Base
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

	validates :name, presence: true, length: { maximum: 64 }
	validates :email, presence: true, length: { maximum: 128 }, format: {with: VALID_EMAIL_REGEX},
			  uniqueness: { case_sensitive: false }

	before_save { self.email = email.downcase }
end