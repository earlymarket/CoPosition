Given(/^the developer "(.*?)" exists$/) do |dev_name|
  @developer = FactoryGirl::create :developer
  @developer.company_name = dev_name
  @developer.save
end

Given(/^the developer "(.*?)" sends me an approval request$/) do |dev_name|
  @developer = Developer.find_by(company_name: dev_name)
  Approval.link(@me,@developer,'Developer')
end

Given(/^I accept the approval request$/) do
  Approval.accept(@me,@developer,'Developer')
end

Then(/^I should see the first "(.*?)" have a class named "(.*?)"$/) do |css, class_name|
  sleep 0.3
  expect(first( :css, css)['class'].include? class_name).to be true
end
