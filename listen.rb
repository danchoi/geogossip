require 'sequel'
require 'eventmachine'
require 'em-websocket'
require 'json'

DB = Sequel.connect("postgres:///geogossip")
port = 9395

@channel_updater = EM::Channel.new

Thread.new do
  DB.listen(['messages'], loop:true) do |channel, pid, payload|
    puts "Notified: #{channel} #{pid} #{payload}"
    puts "#{@channel_updater}"
    channel_id = payload[/channel_id (\d+)/, 1]
    @channel_updater.push({channel: channel, channel_id: channel_id, payload: payload}.to_json)
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
