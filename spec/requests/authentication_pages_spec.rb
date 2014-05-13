require 'spec_helper'
include AuthenticationHelpers

describe "AuthenticationPages" do
	subject { page }

	describe "signin" do
		before { visit signin_path }

		it { should have_content("Sign in") }
		it { should have_title("Sign in") }

		describe 'with invalid information' do
			before { click_button "Sign in" }

			it { should have_title("Sign in") }
			it { should have_error_message('Invalid') }

			describe "after visiting another page" do
				before { click_link "Home" }

				it { should_not have_error_message('Invalid') }
			end
		end

		describe "with valid information" do
			let(:user) { FactoryGirl.create(:user) }
			before { valid_sign_in(user) }

			it_should_behave_like "success sign in"

			describe "followed by signout" do
				before { click_link "Sign out" }

				it { should have_link('Sign in') }
			end
		end
	end
end
