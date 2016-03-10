fdata = File.read("20141215001902_add_states_and_countries.rb")
4000.downto(1).each do
  |num| fdata.gsub!(":id=>"+"#{num},",'')
  end
File.open("20141215001902_add_states_and_countries_new.rb", "w") { |f| f.write(fdata)}
