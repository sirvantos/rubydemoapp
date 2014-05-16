require 'spec_helper'
include AuthenticationHelpers

describe "User Pages" do
	subject { page }

	describe 'Index' do
		before do
			valid_sign_in FactoryGirl.create(:user)
			visit users_path
		end

		it { should have_title('All users') }
		it { should have_content('All users') }

		describe "pagination" do

			before(:all) { 30.times { FactoryGirl.create(:user) } }
			after(:all)  { User.delete_all }

			it { should have_selector('div.pagination') }

			it "should list each user" do
				User.paginate(page: 1).each do |user|
					expect(page).to have_selector('li', text: user.name)
				end
			end
		end

		describe "delete links" do
			it { should_not have_link('delete') }

			describe "as an admin user" do
				let(:admin) { FactoryGirl.create(:admin) }

				before do
					valid_sign_in admin
					visit users_path
				end

				it { should have_link('delete', href: user_path(User.first)) }

				it "should be able to delete another user" do
					expect do
						click_link('delete', match: :first)
					end.to change(User, :count).by(-1)
				end

				it { should_not have_link('delete', href: user_path(admin)) }
			end
		end
	end

	describe "Signup Page" do
		before { visit signup_path }

		it { should have_content("Sign up") }
		it { should have_title(full_title("Sign up")) }
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

	describe "edit" do
		let(:user) { FactoryGirl.create(:user) }
		before do
			valid_sign_in(user)
			visit edit_user_path(user)
		end

		describe "page" do
			it { should have_content("Update your profile") }
			it { should have_title("Edit user") }
			it { should have_link('change', href: 'http://gravatar.com/emails') }
		end

		describe "with invalid information" do
			before { click_button "Save changes" }

			it { should have_content('error') }
		end

		describe "with valid information" do
			let(:new_name) { "New Name" }
			let(:new_email) { "new@email.com" }

			before do
				fill_in "Name",             with: new_name
				fill_in "Email",            with: new_email
				fill_in "Password",         with: user.password
				fill_in "Confirmation", 	with: user.password
				click_button "Save changes"
			end

			it { should have_title(new_name) }
			it { should have_success_message('Your data has been changed') }
			it { should have_link('Sign out', href: signout_path) }

			specify { expect(user.reload.name).to  eq new_name }
			specify { expect(user.reload.email).to eq new_email }
		end
	end
end
