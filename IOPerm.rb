module IOPerm

	# this is a strange function, return nil in case of success, otherwise an error string

	def self.echeck(required_file)

		if (File.directory?(required_file))
			return "err file \"#{required_file}\" is a directory"
		end

		# check if the dir where file shall be created is writable
		if (!File.exist?(required_file) && !File.writable?(File.dirname(required_file)))
			return "err directory \"#{File.dirname(required_file)}\" for file \"#{required_file}\" inexistent or unwritable"
		end

		if (File.exist?(required_file) && !File.writable?(required_file))
			return "err file \"#{required_file}\" exist but isn't writable"
		end

		return nil; # success

	end

end
