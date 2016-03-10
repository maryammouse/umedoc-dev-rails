source 'https://rubygems.org'

ruby "2.2.2"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.3'
# Use SCSS for stylesheets
# https://github.com/twbs/bootstrap-sass#a-ruby-on-rails
gem 'bootstrap-sass', '~> 3.3.5'
gem 'sass-rails', '~> 5.0.3'
gem 'autoprefixer-rails', '~> 5.2.1'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 2.7.1'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyrhino', '~> 2.0.4'
# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 4.0.4'
gem 'jquery-ui-rails', '~> 5.0.5'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 2.5.3'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.3.1'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.1',                            group: :doc
# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.10'
# Use OpenTok for video conferences (aka visits!)
gem "opentok", "~> 2.2.4"
# Use Stripe for Payment Processing
gem 'stripe', '~> 1.27.0'
# More useful logging  - browser details
gem 'browser_details'
# email exceptions
gem 'exception_notification'
# Composite primary keys
gem 'composite_primary_keys', '8.1.1'
# Use passenger as the app server
# gem 'passenger', '4.0.59'
# Use puma as the app server
gem 'puma'
# So we can validate dates & times (11.25.14)
gem 'jc-validates_timeliness', '~> 3.1.1'
# So we can use autocomplete like elation
gem 'rails3-jquery-autocomplete'
gem 'geocoder', '~> 1.2.9'
gem 'authy', '~> 2.4.2'
gem 'twilio-ruby', '~> 4.3.0'
# nice urls
gem 'friendly_id', '~> 5.1.0' # Note: You MUST use 5.0.0 or greater for Rails 4.0+
gem 'pg', '~> 0.18.2'
gem 'rails_12factor'

gem 'momentjs-rails', '>= 2.10.3'
gem 'bootstrap3-datetimepicker-rails', '~> 4.15.35'
gem 'chronic', '~> 0.10.2'
gem 'kaminari', '~> 0.16.3'

gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'daemons'

#gem 'aws-sdk', '~> 2'
# gem 'aws-sdk-rails', '~> 1.0'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development
#
#
# FOR USE IN HEROKU TO QUICKLY DEMO APP
# ORIGINALLY INSIDE group :development, :test
gem 'smarter_csv', '~> 1.1.0'
gem "factory_girl_rails" # "~> 4.5.0"
gem 'forgery', '~> 0.6.0'
gem "faker", "~> 1.4.3"

group :development, :test do
  gem 'web-console', '~> 2.2.1'
  gem "rspec-rails", "~> 3.3.3"
  gem 'guard-rspec', '4.6.4'
  gem 'spring-commands-rspec', '~> 1.0.4'
  gem 'byebug', '~> 5.0.0' # not compatible with jruby
  gem 'brakeman'
  gem 'guard-brakeman'
  gem 'timecop', '~> 0.8.0'
  gem 'annotate', '~> 2.6.10'
  gem 'rack_session_access', '~> 0.1.1'
  gem 'vcr', '~> 2.9.3'
  gem 'stripe-ruby-mock', '~> 2.2.0', :require => 'stripe_mock'
  gem 'stripe_tester', "~> 0.3.2"
end

group :test do
#  gem "cucumber-rails", "~> 1.4.2", require: false
  gem "capybara", "~> 2.4.4"
  gem "database_cleaner", "~> 1.4.1"
  gem "launchy", "~> 2.4.3"
  gem "selenium-webdriver"
  gem 'capybara-screenshot'
  gem 'poltergeist'
  gem "shoulda-matchers", "~> 2.8.0"
  gem 'simplecov', '0.10.0', :require => false
  gem 'webmock', '~> 1.21.0'
  gem 'parallel_tests'
end



