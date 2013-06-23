require 'sequel'

DB = Sequel.connect "postgres:///geogossip"
DB.tables.each do |table|
  puts table
end 

