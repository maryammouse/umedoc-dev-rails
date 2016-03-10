# == Schema Information
#
# Table name: specialty_member_boards
#
#  id        :integer          not null, primary key
#  specialty :string(64)       not null
#  board     :string(64)       not null
#

require 'rails_helper'

RSpec.describe SpecialtyMemberBoard, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
