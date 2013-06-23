require 'sinatra'
require 'json'

get '/' do
  
  form = <<END
    <form action="/messages" method="POST">
       <input type="text" name="name"/>
       <input type="submit"/>
    </form>
END
end 

post '/messages' do 
   puts "POST data: #{request.body.read}"
end 
