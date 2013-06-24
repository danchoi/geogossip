require 'sequel'
require 'eventmachine'
require 'em-websocket'
require 'json'
require 'active_record'
require 'json'

class User < ActiveRecord::Base
  self.primary_key = "user_id"
  has_many :messages
  has_many :memberships
end
class Message < ActiveRecord::Base
  self.primary_key = "message_id"
  belongs_to :user
  belongs_to :channel
end
class Channel < ActiveRecord::Base
  self.primary_key = "channel_id"
  has_many :memberships
  has_many :users, :through => :memberships
  has_many :messages, order: "message_id desc"
end
class Membership < ActiveRecord::Base
  self.primary_key = "membership_id"
  belongs_to :user
  belongs_to :channel
end

ActiveRecord::Base.establish_connection(
  host: "localhost",
  adapter: "postgresql",
  database: "geogossip",
  pool: 15
)

ActiveRecord::Base.include_root_in_json = false


DB = Sequel.connect("postgres:///geogossip")
port = 9395

@channel_updater = EM::Channel.new

Thread.new do
  DB.listen(['messages'], loop:true) do |channel, pid, payload|
    puts "Notified: #{channel} #{pid} #{payload}"
    puts "#{@channel_updater}"
    channel_id = payload[/channel_id (\d+)/, 1]

    channel_obj = Channel.find channel_id.to_i
    channel_obj = channel_obj.attributes.merge(
      users: channel_obj.users,
      messages: channel_obj.messages.limit(20).reverse,
      latLng: (channel_obj.lat && channel_obj.lng) ? [channel_obj.lat, channel_obj.lng] : nil
    )
    puts "Sending channel_obj: #{channel_obj}"
    vals2 = {channel_obj: channel_obj, channel: channel, channel_id: channel_id, payload: payload} 

    @channel_updater.push(vals2.to_json)
  end
end

EventMachine.run do

#startup a websocket thingy
  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => port, :debug => true) do |ws|

    ws.onopen do
      puts "new connection"
      #need to subscribe the user
      sid = @channel_updater.subscribe {|msg|
        ws.send msg
      }
      
      ws.onclose do
        #need to unsubscribe the user
        @channel_updater.unsubscribe(sid)
      end
    end
  end
  puts "Started websocket at #{port}"
end
