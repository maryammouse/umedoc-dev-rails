# == Schema Information
#
# Table name: specialty_member_boards
#
#  id        :integer          not null, primary key
#  specialty :string(64)       not null
#  board     :string(64)       not null
#

class SpecialtyMemberBoard < ActiveRecord::Base
end
