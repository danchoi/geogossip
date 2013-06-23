require 'sequel'

DB = Sequel.connect("postgres:///geogossip")

DB.listen(['messages'], loop:true) do |channel, pid, payload|
  puts "Notified: #{channel} #{pid} #{payload}"
end

