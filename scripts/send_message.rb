#!/usr/bin/ruby
# author: Alex Maimescu
# twitter: https://twitter.com/amaimescu

require './http_client'
require 'json'

ENDPOINT = "send"

arguments = ARGV[0]
params = nil

if arguments == nil
	params = { 
		'project' => 'Insider',
		'action'=> 'send_message'
	}
else
	params = JSON.parse(arguments)
end

puts "Send POST request with params #{params}"
send_post_request(ENDPOINT, params)