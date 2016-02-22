# author: Alex Maimescu
# twitter: https://twitter.com/amaimescu

require 'net/http'

TESTING_HTTP_SERVER_URL = 'http://localhost:8080/'

def send_post_request(endpoint, params)
	url = URI.parse(TESTING_HTTP_SERVER_URL + endpoint)
	req = Net::HTTP::Post.new(url.to_s)
	req.body = URI.encode_www_form(params)
	res = Net::HTTP.start(url.host, url.port) {|http|
  		http.request(req)
	}
end

def send_get_request(endpoint)
	url = URI.parse(TESTING_HTTP_SERVER_URL + endpoint)
	req = Net::HTTP::Get.new(url.to_s)
	res = Net::HTTP.start(url.host, url.port) {|http|
  		http.request(req)
	}
end