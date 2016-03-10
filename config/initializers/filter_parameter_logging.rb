# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters +=
  [:password, :firstname, :lastname, :date_of_birth, :gender,
    :number, :phone_type, # phone
    :mailing_name, :address_type, # addresses
    :street_address_1, :street_address_2, :city, :state, :zip_code, # addresses
    :awarded_by, :general_practice, :specialty_opt1, :specialty_opt2, :license_number, # temporary_credentials
    :name, :body] # chat_entries

# Last updated 2.14.15 - to be updated when new forms added
  # Guiding principle: Filter all info that is personally identifiable,
  # only keep info necessary for debugging, e.g. id
