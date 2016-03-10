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

require 'rails_helper'

RSpec.describe ChatEntry, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
