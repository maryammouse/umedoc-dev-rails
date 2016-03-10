# == Schema Information
#
# Table name: chat_entries
#
#  id           :integer          not null, primary key
#  body         :text             not null
#  connectionid :string(255)      not null
#  session_id   :string(255)      not null
#  name         :string(255)      not null
#  created_at   :datetime         not null
#

FactoryGirl.define do
  factory :chat_entry do
    body "MyText"
connectionId "MyString"
  end

end
