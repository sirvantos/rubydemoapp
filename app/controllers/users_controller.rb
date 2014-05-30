class UsersController < ApplicationController
	before_action :signed_in_user, only: [:index, :edit, :update, :destroy, :following, :followers]
	before_action :signed_out_user, only: [:create, :new]
	before_action :correct_user,   only: [:edit, :update]
	before_action :admin_user,     only: :destroy

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
			UserMailer.registration_confirmation(@user).deliver

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
end
