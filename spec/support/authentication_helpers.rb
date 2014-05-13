module AuthenticationHelpers
	def full_title(page_title)
		base_title = "Ruby on Rails Tutorial Sample App"
		if page_title.empty?
			base_title
		else
			"#{base_title} | #{page_title}"
		end
	end

	def valid_sign_in(user)
		fill_in "Email",    with: user.email
		fill_in "Password", with: user.password
		click_button "Sign in"
	end

	def fill_signup_with_valid_user(user)
		fill_in "Name", with: user.name
		fill_in "Email", with: user.email
		fill_in "Password", with: user.password
		fill_in "Confirmation", with: user.password_confirmation
	end

	shared_examples_for "success sign in" do
		it { should have_title(user.name) }
		it { should have_link('Profile', href: user_path(user)) }
		it { should have_link('Sign out', href: signout_path) }
		it { should_not have_link('Sign in', href: signin_path) }
	end
end