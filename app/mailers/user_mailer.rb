class UserMailer < ActionMailer::Base
	default from: "from@example.com"

	def registration_confirmation(user)
		@user = user
		mail(to: @user.email, subject: 'Welcome to My Awesome Site', from: "webmaster@example.com")
	end
end
