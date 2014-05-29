require 'spec_helper'
require 'pp'

include AuthenticationHelpers
include ActionView::Helpers::OutputSafetyHelper

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
			it { should have_content(
							'Micropost'.pluralize( user.microposts.count ) + ' (' + user.microposts.count.to_s	+ ')') }
		end

		describe "microposts pagination" do

			before do
				30.times { FactoryGirl.create(:micropost, user: user) }
				visit user_path(user)
			end

			after { user.microposts.delete_all }

			it { should have_selector('div.pagination') }

			it "should list each user" do
				user.microposts.paginate(page: 1).each do |micropost|
					expect(page).to have_selector('li', text: micropost.content)
				end
			end

			describe "micropost delete link" do
				let(:another_user) { FactoryGirl.create(:user) }
				let!(:m3) { FactoryGirl.create(:micropost, user: another_user, content: "Foo") }
				let!(:m4) { FactoryGirl.create(:micropost, user: another_user, content: "Bar") }

				before do
					valid_sign_in(another_user)
					visit user_path(user)
				end

				it "should not have delete link" do
					should_not have_link('delete')
				end
			end
		end

		describe 'micropost long content' do
			let!(:long_micropost) { FactoryGirl.create(:micropost, user: user,
				content: "helloooooooooooooooooooooooooooooooooooooooooooooossssssssssdddddddddddddddddd") }

			before { visit user_path(user) }

			it { page.find('li#' + long_micropost.id.to_s + ' span.content').text == rspec_wrap(long_micropost.content) }

			it 'should have separate sign' do
				page.find('li#' + long_micropost.id.to_s + ' span.content')
					.text.split(rspec_html_entities_encode("&#8203;"))
						.length.should == (long_micropost.content.length / 30.0).ceil
			end
		end

		describe 'follow/unfollow buttons' do
			let(:other_user) { FactoryGirl.create(:user) }
			before { valid_sign_in user }

			describe "following a user" do
				before { visit user_path(other_user) }

				it "should increment the followed user count" do
					expect do
						click_button "Follow"
					end.to change(user.followed_users, :count).by(1)
				end

				it "should increment the other user's followers count" do
					expect do
						click_button "Follow"
					end.to change(other_user.followers, :count).by(1)
				end

				describe "toggling the button" do
					before { click_button "Follow" }
					it { should have_xpath("//input[@value='Unfollow']") }
				end
			end

			describe "unfollowing a user" do
				before do
					user.follow!(other_user)
					visit user_path(other_user)
				end

				it "should decrement the followed user count" do
					expect do
						click_button "Unfollow"
					end.to change(user.followed_users, :count).by(-1)
				end

				it "should decrement the other user's followers count" do
					expect do
						click_button "Unfollow"
					end.to change(other_user.followers, :count).by(-1)
				end

				describe "toggling the button" do
					before { click_button "Unfollow" }
					it { should have_xpath("//input[@value='Follow']") }
				end
			end

			describe "user's stat" do
				before do
					visit user_path(other_user)
					click_button "Follow"
				end

				describe "followed user" do
					before { visit user_path(user) }

					it { should have_link("1 following", href: following_user_path(user)) }
					it { should have_link("0 followers", href: followers_user_path(user)) }
				end

				describe "following user" do
					before { valid_sign_in other_user }

					it { should have_link("0 following", href: following_user_path(other_user)) }
					it { should have_link("1 followers", href: followers_user_path(other_user)) }
				end
			end
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

				it { should have_success_message('Hello, we have sent confirmation email. Please check your mail') }
				it { should have_title('') }
				it { should have_link('Sign in', href: signin_path) }

				describe "should not be signable" do
					let(:sign_up_user) { FactoryGirl.create(:user) }

					before { valid_sign_in(sign_up_user, not_confirmed: true) }

					it { should have_title('') }
					it { should have_link('Sign in', href: signin_path) }
					it { should have_error_message('Invalid email/password combination') }
					it { sign_up_user.confirmation_hash.should_not be_nil }
				end

				describe "should confirm sign up" do
					before do
						valid_sign_in(sign_up_user)
						visit registration_confirmation(sign_up_user, sign_up_user.confirmation_hash)

						should_behave_like "success sign in"
					end
				end
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

	describe "following/followers" do
		let(:user) { FactoryGirl.create(:user) }
		let(:other_user) { FactoryGirl.create(:user) }
		before { user.follow!(other_user) }

		describe "followed users" do
			before do
				valid_sign_in user
				visit following_user_path(user)
			end

			it { should have_title(full_title('Following')) }
			it { should have_selector('h3', text: 'Following') }
			it { should have_link(other_user.name, href: user_path(other_user)) }
		end

		describe "followers" do
			before do
				valid_sign_in other_user
				visit followers_user_path(other_user)
			end

			it { should have_title(full_title('Followers')) }
			it { should have_selector('h3', text: 'Followers') }
			it { should have_link(user.name, href: user_path(user)) }
		end
	end
end
