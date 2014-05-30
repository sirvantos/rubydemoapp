require "spec_helper"

describe UserMailer do
	describe 'templates' do
		let(:user) { FactoryGirl.create(:user) }
		let(:mail) { UserMailer.registration_confirmation(user) }

		describe "confirmation mail" do
			it "should have subject" do
				expect(mail.subject).to eql('Welcome to My Awesome Site')
			end

			it "should have to" do
				expect(mail.to).to eql([user.email])
			end

			it "should have name" do
				expect(mail.body.encoded).to match(user.name)
			end

			it "should have confirmation url" do
				expect(mail.body.encoded).to match(registration_confirmation_user_path(user, user.confirmation_hash))
			end
		end
	end
end
