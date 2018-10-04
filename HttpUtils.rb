require 'uri'
require 'net/http'

module HttpUtils

	# get only header (ignore don't read & map response body into memory)
	# usage: get_response_hdr(fetch(url)).to_hash

	def self.get_response(uri_str, hmap = {}, follow_redirection = true)

		uri = follow_redirection ? URI.parse(fetch(uri_str, hmap)) : URI.parse(uri_str)
		req = Net::HTTP::Get.new(uri)
		hmap.each {|k,v| req[k] = v }

		# enable ssl if uri.scheme == https
		Net::HTTP.start(uri.host, uri.port, { :use_ssl => uri.scheme == 'https' } ) do |http|
			http.request(req)
		end
	end

	# http://ruby-doc.org/stdlib-2.4.2/libdoc/net/http/rdoc/Net/HTTP.html
	# follow n redirection (which n is limit) and return the final url destination 
	# hmap is the header map that will be used for send these request

	def self.fetch(uri_str, hmap = {}, limit = 10)

		raise(ArgumentError, 'err too many HTTP redirects') if limit == 0

		# wee need only of header
		case (response = get_response(uri_str, hmap, false))
		when Net::HTTPSuccess then
			return uri_str.to_s
		when Net::HTTPRedirection then
			location = response['location']

			# base url workaround
			uri = URI(uri_str)
			location = location[0] == '/' ? (uri.scheme + "://" +  uri.host + location) : location;

			warn "redirected to #{location}"
			return fetch(location, hmap, limit - 1)
		else
			return response.value
		end
	end

end
