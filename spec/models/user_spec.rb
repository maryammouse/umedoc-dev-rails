# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  firstname              :string(255)      not null
#  lastname               :string(255)      not null
#  dob                    :date             not null
#  created_at             :datetime
#  updated_at             :datetime
#  gender                 :string(255)      not null
#  username               :string(255)      not null
#  password_digest        :string(255)      not null
#  authy_id               :string(255)      not null
#  cellphone              :string(50)       not null
#  country_code           :string(5)        default("1"), not null
#  slug                   :text
#  password_reset_token   :string
#  password_reset_sent_at :datetime
#

require 'rails_helper'

describe "User", focus:false do

  describe "User is valid with:" do

      it "is valid with a username, password, firstname, lastname, dob, gender" do
        user = build(:user)
        user.valid?
        expect(user).to be_valid
      end

  end

  describe "User is invalid without: " do

    fields = %i{ username password firstname lastname dob gender }
    fields.each do |field|
      it "is invalid if #{ field } is nil" do
        user = build(:user,
                    field => nil)
        user.valid?
        expect(user.errors[field]).to include("can't be blank")
      end
    end
  end

  describe "User is invalid with incorrect: " do

    test_array =  [
               ['username',  'Princess@nnaNOtemail', "is not valid in our system. Sorry about that!"],
               #['password',  'Princess@nna', "We're sorry, our system can't handle that password"],
               ['password',  'Princesslnnaasasfsdfasfasfsafsafsakfshfashfkasdfhkasfhaskfafsdfasfdsfasfasfasfsd', "is too long (maximum is 72 characters)"],
               ['password',  'moderf@ker!no', "has characters our system can't handle. We're sorry!"],
               ['firstname',  'Princess@nna', "has characters our system can't handle. We're sorry!"],
               ['lastname',   'Princess@nna', "has characters our system can't handle. We're sorry!"],
               ['gender',     'mal',          'must be male, female, or other'],
               ['dob',        'lalalloopsy',  'is not a valid date'],
               ['dob',        '123456111111133333333333333331',  'is not a valid date'],
    ]


    test_array.each do |field_name, field_value, field_error|
        it "is invalid with incorrect #{ field_name }: #{ field_value } " do
          user = build(:user,
                      field_name => field_value)
          user.valid?
          expect(user.errors[field_name]).to include(field_error)
      end
    end

    it "is invalid with incorrect dob - under 18" do
         user = build(:user,
                     dob: 18.years.ago + 1.day )
         # The expression for dob should always give a date one day less than 18 years ago
         # compared to the date of running the test
         user.valid?
         expect(user.errors[:dob]).to include("must be at least 18 years old")
    end
  end

  describe "username specific:" do
    it "is not possible to create two identical usernames" do
      user1 = create(:user, username: 'marcella@gmail.com')
      user2 = build(:user, username: 'marcella@gmail.com')
      user2.valid?
      expect(user2.errors[:username]).to include('has already been taken')
    end
  end

  describe "Friendly urls" do
    it "is different for docs of same last name" do
      doctor1 = FactoryGirl.create(:doctor)
      user1 = doctor1.user
      user2 = FactoryGirl.create(:user, lastname: doctor1.user.lastname)
      doctor2 = FactoryGirl.create(:doctor, user_id: user2.id)
      #puts user1.slug
      #puts user2.slug

      expect(user1.slug).not_to eq(user2.slug)
    end

    it "is different for docs of same last name and firstname" do
      doctor1 = FactoryGirl.create(:doctor)
      user1 = doctor1.user
      user2 = FactoryGirl.create(:user,
                                 firstname: doctor1.user.firstname,
                                 lastname: doctor1.user.lastname)
      doctor2 = FactoryGirl.create(:doctor, user_id: user2.id)
      user3 = FactoryGirl.create(:user,
                                firstname: doctor1.user.firstname,
                                lastname: doctor1.user.lastname)
      doctor3 = FactoryGirl.create(:doctor, user_id: user3.id)
      #puts user2.slug
      #puts user3.slug

      expect(user2.slug).not_to eq(user3.slug)
    end
  end

  describe User do
    it { should have_one(:doctor) }
    it { should have_one(:patient) }
    it { should have_many(:phones) }
  end
  
  

    #it "is invalid with duplicate ssn" do
             #user1 = create(:user,
                         #ssn: '123456789' )
             #user2 = build(:user,
                         #ssn: '123456789' )
             #user2.valid?
             #expect(user2.errors[:ssn]).to include("We're sorry, that number is already in our system")
           #end
end
