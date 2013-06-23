require 'active_record'
require 'sinatra'
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
  has_many :messages, order: "created desc"
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

set :public_dir, "public"

get '/' do
  File.read("public/index.html")
end

get '/channels' do
  Channel.order("updated desc").all.map {|channel|
    channel.attributes.merge(
      users: channel.users,
      messages: channel.messages.limit(20),
      latLng: (channel.lat && channel.lng) ? [channel.lat, channel.lng] : nil
    )
  }.to_json
end

post '/channels' do
  payload = JSON.parse(request.body.read)
  puts "POST channels #{payload.inspect}"
  channel = Channel.find_or_create_by_channel_title(payload['channel_title'])
  channel.update_attributes(lat: payload['latLng'][0], lng: payload['latLng'][1])
  puts "#{channel.to_json}"
  channel.to_json 
end

get '/channel/:id' do
  channel = Channel.find params[:id]
  channel.attributes.merge(
    users: channel.users,
    messages: channel.messages.limit(20),
    latLng: (channel.lat && channel.lng) ? [channel.lat, channel.lng] : nil
  ).to_json
end

put '/channels/:id' do
  payload = JSON.parse(request.body.read)
  channel_to_edit = Channel.find_by_channel_id(params[:id])
  channel_to_edit.update_attribute(:channel_title, payload['edited_topic_name'])
  channel_to_edit.to_json
end

get '/users' do
  User.all.to_json
end

post '/users' do
  payload = JSON.parse(request.body.read)
  basename = payload["user_nick"]
  count = 1
  s = ''
  while User.find_by_user_nick(basename + s) 
    s = count.to_s
    count += 1
  end 

  user = User.create( user_nick: basename + s )
  puts "New user: #{user.inspect}"
  user.to_json
end

post '/memberships' do
  payload = JSON.parse(request.body.read)
  user = find_user payload
  channel_id = payload["channel_id"]
  # expire all current memberships
  user.memberships.each {|x| x.update_attributes(terminated: Time.now)}
  m = Membership.find_or_create_by_user_id_and_channel_id( user.id, channel_id)
  m.update_attributes(terminated: nil)
  puts "#{m.to_json}"
  m.to_json
end


post '/messages' do
  payload = JSON.parse(request.body.read)
  user = find_user payload
  channel = Channel.find payload['channel_id']
  res = Message.create(
    user: user, 
    user_nick: user.user_nick,
    channel: channel,
    message_content: payload['message_content']
  )
  puts payload
  res.to_json
end

def find_user payload
  puts "find_user from payload: #{payload.to_json}"
  User.find(payload['user_id']) # may change this impl later
end

