require './app.rb'
run Rack::Cascade.new [API, Web]