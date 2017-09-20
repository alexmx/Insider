#!/usr/bin/ruby
# author: Alex Maimescu
# twitter: https://twitter.com/amaimescu

require './http_client'
require 'json'

ENDPOINT = "sendAndWaitForResponse"

arguments = ARGV[0]
params = nil

if arguments == nil
	params = { 
		'project' => 'Insider',
		'action'=> 'send_message_with_response'
	}
else
	params = JSON.parse(arguments)
end

puts "Send POST request with params #{params}"
response = send_post_request(ENDPOINT, params)
puts "Response: #{response.body}"