require 'ipaddr'

module IPstore

	# validate an ip address
	def self.ip?(ip_str)

		begin
			IPAddr.new(ip_str)
			return true

		rescue; return false; end
	end

	# read previous ip 
	def self.load_from_cache(cache_file)

		ret=nil;

		begin
			File.open(cache_file, "r") { |f| 
				 ret = ip?((s = f.gets.chomp)) ? s : nil;
			}

		rescue;;end
		return ret;

	end

	def self.save_to_cache(ip, cache_file)

		return if !self.ip?(ip)

		begin
			File.open(cache_file, "w") { |f|
				f.puts(ip)
			}

		rescue;;end
	end

end
