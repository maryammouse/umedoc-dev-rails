# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

# add extensions
# http://stackoverflow.com/questions/677034/adding-a-method-to-built-in-class-in-rails-app
require 'rails_extensions'
