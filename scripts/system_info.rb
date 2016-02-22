#!/usr/bin/ruby
# author: Alex Maimescu
# twitter: https://twitter.com/amaimescu

require './http_client'
require 'json'

ENDPOINT = "systemInfo"

puts "Get System Info"
response = send_get_request(ENDPOINT)
puts "System Info:"
puts JSON.pretty_generate(JSON.parse(response.body))