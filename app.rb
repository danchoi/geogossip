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
  Channel.all.map {|channel|
    channel.attributes.merge(
      users: channel.users,
      messages: channel.messages.limit(20)
    )
  }.to_json
end

post '/channels' do
  pesayload = JSON.parse(request.body.read)
  new_channel = Channel.find_or_create_by_channel_title(payload['new_topic_name'])
  puts "#{new_channel.to_json}"
  new_channel.to_json 
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
  user_id = payload["user_id"]
  user = User.find user_id
  channel_id = payload["channel_id"]
  # expire all current memberships
  user.memberships.each {|x| x.update_attributes(terminated: Time.now)}
  m = Membership.find_or_create_by_user_id_and_channel_id( user_id, channel_id)
  m.update_attributes(terminated: nil)
  puts "#{m.to_json}"
  m.to_json
end

