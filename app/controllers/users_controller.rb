class UsersController < ApplicationController
	before_action :signed_in_user, only: [:index, :edit, :update, :destroy, :following, :followers]
	before_action :signed_out_user, only: [:create, :new]
	before_action :correct_user,   only: [:edit, :update]
	before_action :admin_user,     only: :destroy
	before_action :get_user_to_reset_password, only: :reset_user_password

	def index
		@users = User.paginate(page: params[:page])
	end

	def show
		@user = User.find(params[:id])
		@microposts = @user.microposts.paginate(page: params[:page])
	end

	def new
		@user = User.new
	end

	def edit
	end

	def update
		if @user.update_attributes(user_params)
			flash[:success] = "Your data has been changed!"
			redirect_to @user
		else
			render 'edit'
		end
	end

	def create
		@user = User.new(user_params)
		if @user.save
			Resque.enqueue(MailWorker, for: 'registration_confirmation', user: @user)

			flash[:success] = "Hello, we have sent confirmation email. Please check  your mail"
			redirect_to root_path
		else
			render 'new'
		end
	end

	def register_confirmation
		user = User.find_by(id: params[:id], confirmation_hash: params[:confirmation_hash].downcase)
		if user
			user.update_attribute(:confirmation_hash, nil)
			sign_in user
			flash[:success] = "Hello, we have activated your account!"
			redirect_to root_path
		else
			flash[:danger] = "Sorry, wrong confrimation hash!"
			redirect_to root_path
		end
	end

	def password_reset
		if request.post?
			user = User.find_by(email: params[:email].downcase)
			if user
				user.generate_password_reset_hash!
				user.update_attribute(:password_reset_hash, user.password_reset_hash)

				Resque.enqueue(MailWorker, for: 'password_reset_confirmation', user: @user)
				flash[:success] = "Hello, we have sent reset password email. Please check  your mail"
				redirect_to root_path
			else
				flash.now[:danger] = "User with given email has not been found!"
			end
		end
	end

	def reset_user_password
		if request.post?
			if @user.update(password: params[:password], password_confirmation: params[:password_confirmation],
							password_reset_hash: nil)
				flash[:success] = "The password has been reseted!"
				sign_in @user
				redirect_to root_path
			end
		end
	end

	def destroy
		user = User.find(params[:id])

		if !current_user?(user)
			user.destroy
			redirect_to users_url
		else
			redirect_to root_url
		end
	end

	def following
		@title = "Following"
		@user = User.find(params[:id])
		@users = @user.followed_users.paginate(page: params[:page])
		render 'show_follow'
	end

	def followers
		@title = "Followers"
		@user = User.find(params[:id])
		@users = @user.followers.paginate(page: params[:page])
		render 'show_follow'
	end

	private
		def user_params
			params.require(:user).permit(:name, :email, :password, :password_confirmation)
		end

		def correct_user
			@user = User.find(params[:id])
			redirect_to(root_url) unless current_user?(@user)
		end

		def admin_user
			redirect_to(root_url) unless current_user.admin?
		end

		def signed_out_user
			redirect_to root_url if signed_in?
		end

		def get_user_to_reset_password
			@user  = User.find_by(id: params[:id], password_reset_hash: params[:password_reset_hash])
			redirect_to(root_url) unless @user
		end
end
