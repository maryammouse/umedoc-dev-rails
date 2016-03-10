require 'vcr'

# spec/support/vcr_setup.rb
VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = "spec/vcr"
  config.hook_into :webmock # or :fakeweb
  config.ignore_localhost = true
end
