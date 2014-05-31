class User < ActiveRecord::Base
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(?:\.[a-z\d\-]+)*\.[a-z]+\z/i

	has_many :microposts, dependent: :destroy
	has_many :relationships, foreign_key: "follower_id", dependent: :destroy
	has_many :reverse_relationships, foreign_key: "followed_id", class_name:  "Relationship", dependent:   :destroy
	has_many :followed_users, through: :relationships, source: :followed
	has_many :followers, through: :reverse_relationships

	validates :name, presence: true, length: { maximum: 64 }
	validates :confirmation_hash, presence: false, length: { maximum: 32 }
	validates :password_reset_hash, presence: false, length: { maximum: 32 }
	validates :email, presence: true, length: { maximum: 128 }, format: {with: VALID_EMAIL_REGEX},
			  uniqueness: { case_sensitive: false }
	validates :password, length: { minimum: 6 }

	has_secure_password

	before_save { email.downcase! }
	before_create :create_remember_token, :create_confirmation_hash

	def self.new_remember_token
		SecureRandom.urlsafe_base64
	end

	def self.digest(token)
		Digest::SHA1.hexdigest(token.to_s)
	end

	def feed
		Micropost.from_users_followed_by(self)
	end

	def following?(other_user)
		relationships.find_by(followed_id: other_user.id)
	end

	def follow!(other_user)
		relationships.create!(followed_id: other_user.id)
	end

	def generate_password_reset_hash!
		self.password_reset_hash = generate_md5_hash()
	end

	def unfollow!(other_user)
		relationships.find_by(followed_id: other_user.id).destroy
	end

	private

		def create_remember_token
			self.remember_token = User.digest(User.new_remember_token)
		end

		def create_confirmation_hash
			self.confirmation_hash = generate_md5_hash
		end

		def generate_md5_hash
			Digest::MD5.hexdigest(SecureRandom.urlsafe_base64.to_s)
		end
end