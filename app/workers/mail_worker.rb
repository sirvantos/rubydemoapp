class MailWorker
	@queue = :mail

	def self.perform(params)
		case params[:for]
			when "registration_confirmation"
				UserMailer.registration_confirmation(params.user).deliver
			when "password_reset_confirmation"
				UserMailer.password_reset_confirmation(params.user).deliver
		end
	end
end
