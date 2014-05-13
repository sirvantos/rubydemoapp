require 'spec_helper'
include AuthenticationHelpers

describe "User Pages" do
	subject { page }

	describe "Signup Page" do
		before { visit signup_path }

		it {should have_content("Sign up")}
		it {should have_title(full_title("Sign up"))}
	end

	describe "Profile page" do
		let(:user) { FactoryGirl.create(:user) }

		before { visit user_path(user)}

		it { should have_content(user.name) }
		it { should have_title(user.name) }
	end

	describe "signup" do
		before { visit signup_path }

		let (:submit) { "Create my account" }

		describe "with invalid information" do
			it "should not create a user" do
				expect { click_button submit }.not_to change(User, :count)
			end

			describe "after submission" do
				before { click_button submit }

				it { should have_title('Sign up') }
				it { should have_error_message('The form contains') }
			end
		end

		describe "with valid information" do
			let(:sign_up_user) { FactoryGirl.build(:user) }

			before { fill_signup_with_valid_user(sign_up_user) }

			it "should create a user" do
				expect { click_button submit }.to change(User, :count).by(1)
			end

			describe "after submission" do
				before { click_button submit }
				let(:user) { User.find_by(email: sign_up_user.email) }

				it_should_behave_like "success sign in"
			end
		end
	end
end
