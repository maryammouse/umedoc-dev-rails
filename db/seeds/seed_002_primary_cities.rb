# encoding: UTF-8
# This file is auto-generated from the current content of the database. Instead
# of editing this file, please use the migrations feature of Seed Migration to
# incrementally modify your database, and then regenerate this seed file.
#
# If you need to create the database on another system, you should be using
# db:seed, not running all the migrations from scratch. The latter is a flawed
# and unsustainable approach (the more migrations you'll amass, the slower
# it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Base.transaction do
  # import csv and other setup
  zip_hash = SmarterCSV.process('db/data/zip_code_database.csv')
  city_array= []

  # clean up data, extract primary_city values into, remove unneeded keys & value = columns
  zip_hash.each do |record|
    record[:zip]=record[:zip].to_s.insert 0,'0'*(5-record[:zip].to_s.length)
    city_array << record[:primary_city]
    record.delete(:acceptable_cities)
    record.delete(:unacceptable_cities)
    record.delete(:world_region)
  end

  # Delete and reseed PrimaryCity
  PrimaryCity.delete_all
  city_array.uniq!.sort!
  city_array.each do |city_name|
    PrimaryCity.create :name => city_name
  end

  # Delete and reseed ZipCode, placed after PrimaryCity which is referenced by ZipCode
  ZipCode.delete_all
  zip_hash.each do |record|
    ZipCode.create record
  end

end
