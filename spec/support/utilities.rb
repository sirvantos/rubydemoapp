include ActionView::Helpers::SanitizeHelper
include ApplicationHelper
include MicropostsHelper

RSpec::Matchers.define :have_error_message do |message|
	match do |page|
		expect(page).to have_selector('div.alert.alert-danger', text: message)
	end
end

RSpec::Matchers.define :have_success_message do |message|
	match do |page|
		expect(page).to have_selector('div.alert.alert-success', text: message)
	end
end

def rspec_html_entities_encode text
	coder = HTMLEntities.new
	coder.decode text
	end

def rspec_wrap text
	rspec_html_entities_encode wrap text
end

def rspec_strip_tags text
	strip_tags text
end