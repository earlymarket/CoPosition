if Rails.env.test?
  require "webmock/rspec"
  WebMock.disable_net_connect!(allow_localhost: true)
end
