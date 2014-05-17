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


				describe "should not be able to delete itself" do
					before do
						valid_sign_in admin, no_capybara: true
						delete user_path(admin)
					end

					specify { expect(response).to redirect_to(root_path) }

					it "should not be able to delete itself (users count should not be changed)" do
						expect { delete user_path(admin) }.not_to change(User, :count)
					end
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
		let!(:m1) { FactoryGirl.create(:micropost, user: user, content: "Foo") }
		let!(:m2) { FactoryGirl.create(:micropost, user: user, content: "Bar") }

		before { visit user_path(user)}

		it { should have_content(user.name) }
		it { should have_title(user.name) }

		describe "microposts" do
			it { should have_content(m1.content) }
			it { should have_content(m2.content) }
			it { should have_content(user.microposts.count) }
		end
	end

	describe "signup" do
		before { visit signup_path }

		let (:submit) { "Create my account" }

		it { should have_button('Create my account') }

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

	describe "sign up for signed user" do
		let(:user) { FactoryGirl.create(:user) }
		before { valid_sign_in(user, no_capybara: true) }

		describe "go to sign up page" do
			before { get signup_path }
			specify { expect(response).to redirect_to(root_path) }
		end

		describe "create new user" do
			before { post users_path }
			specify { expect(response).to redirect_to(root_path) }
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
			it { should have_button('Save changes') }
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

		describe "forbidden attributes" do
			let(:params) do {
				user: {
					admin: true,
					password: user.password,
					password_confirmation: user.password
				}
			}
			end

			before do
				valid_sign_in user, no_capybara: true
				patch user_path(user), params
			end

			specify { expect(user.reload).not_to be_admin }
		end
	end
end
