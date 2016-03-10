# == Schema Information
#
# Table name: state_medical_boards
#
#  name    :string(255)      not null
#  state   :string(2)        not null
#  country :string(3)        not null
#  id      :integer          not null, primary key
#

require 'rails_helper'

RSpec.describe StateMedicalBoard, :type => :model do
  context "Rails Associations" do
      describe StateMedicalBoard do
        it { should have_many(:medical_licenses)}
      end
    end

end
