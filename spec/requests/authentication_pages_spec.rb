require 'spec_helper'

describe "AuthenticationPages" do
	subject { page }

	describe "sign in" do
		before { visit signin_path }

		it { should have_content("Sign in") }
		it { should have_title("Sign in") }
	end
end
