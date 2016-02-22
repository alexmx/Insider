#!/usr/bin/ruby
# author: Alex Maimescu
# twitter: https://twitter.com/amaimescu

require './http_client'
require 'json'

ENDPOINT = "invoke"

arguments = ARGV[0]
params = nil

if arguments == nil
	params = { 
		'project' => 'Insider',
		'action'=> 'invoke_method'
	}
else
	params = JSON.parse(arguments)
end

puts "Send POST request with params #{params}"
send_post_request(ENDPOINT, params)