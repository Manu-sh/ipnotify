#!/usr/bin/ruby

require 'uri'
require 'net/http'
require 'logger'
require 'socket'
require 'getoptlong'

require 'gmail'

require_relative 'IOPerm.rb'
require_relative 'IPstore.rb'
require_relative 'HttpUtils.rb'


# https://github.com/gmailgem/gmail
# $ gem install gmail

# if you launch using root install also gmail for root account
# sudo gem install gmail

# TODO timeout as opt

def mail_body(hostname,ip)

mail_body = <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">
<html><style> body { background-color: white; color: #24292E; } .container { padding: 3% 13% 3% 13%; }
a { color: #076AD3; background-color: #F6F8FA; border-radius: 8%; padding: 5% 3% 5% 3%; border: 
1px solid #c3c3c3; text-align: center; } a:link { font-size: 13px; text-decoration: none; text-transform: uppercase; 
display: inline-block; padding: 3px 3px 3px 3px } a:hover { color: #E2574E; background-color: #F6F8FA; }
</style><head><title>#{hostname}</title></head><body><div class="container"><h2 align=center>New public IP address</h2>
<h3 align=center>#{hostname} <a target="blank" href="https://www.iplocation.net/?query=#{ip}">#{ip}</a></h3>
</div></body></body></html>
EOF

	return mail_body;
end

def sendgmail(as_html, my_mail, my_passwd, mail_obj, mail_body)
	ret=false
	begin
		Gmail.connect(my_mail, my_passwd) do |gmail|
			if ((ret = gmail.logged_in?))
				email = gmail.compose do
					to(my_mail)
					subject(mail_obj)
					if as_html
						body(mail_body)
					else
						html_part {
							content_type('text/html; charset=UTF-8')
							body(mail_body)
						}
					end
				end
				email.deliver
			end
		end

	rescue;;end
	return ret
end

# ifconfig.me reject Ruby as user-agent, in case of success return the public ip otherwise ""
def get_ip(url_str = "http://ifconfig.me")

	begin
		return IPstore::ip?(
			(ip = HttpUtils::get_response(url_str, { 'User-Agent' => 'curl/7.57.0' }).body.chomp)
		) ? ip : "";
	rescue => e
		$logger.warn('get_ip()') { "#{e} at line: #{__LINE__}" }
		STDERR.puts("get_ip() failed: #{e}") if (!$opt[:daemon])
		return ""
	end
end


# default that only cmd options can override
# this structure prevails over the others
# in order: cmd_opt > $cfg > $opt

cmd_opt = {
	cfgfile: '/etc/ipnotify.cfg',
	daemon: false
}

# default parameters that cfg file ($cfg) can override
# the cfg file MUST always provide at least mail and passwd

$opt = {
	logfile:   '/dev/null',
	cachefile: '/var/cache/ipnotify.cache',
	pidfile:   '/var/run/ipnotify.pid',
	mail:      "",
	passwd:    "",
	hostname:  Socket.gethostname.to_s,
	textonly:  false
}

opts = GetoptLong.new(
	[ '--help',       '-h', GetoptLong::NO_ARGUMENT ],
	[ '--plain-text', '-t', GetoptLong::NO_ARGUMENT ],
	[ '--daemon',     '-d', GetoptLong::OPTIONAL_ARGUMENT ],
	[ '--hostname',	        GetoptLong::OPTIONAL_ARGUMENT ],
	[ '--log',        '-l', GetoptLong::OPTIONAL_ARGUMENT ],
	[ '--config',     '-c', GetoptLong::REQUIRED_ARGUMENT ],
	[ '--cache',      '-k', GetoptLong::REQUIRED_ARGUMENT ]
)

USAGE = <<EOF
ipnotify usage:
	-h, --help
		this help
	-c, --config
		specify a different config file, default is
		/etc/ipnotify.cfg
	-d, --daemon
		run as daemon, you can specify a different pidfile
		default is /var/run/ipnotify.pid, or 
	-l, --log
		enable log, you can specify a different file log
		default is /var/log/ipnotify.log
	--cache
		specify a different cache file, default is
		/var/cache/ipnotify.cache
	--hostname
		the mail object is the hostname of machine followed by the new ip
		if you want override this value use --hostname 'mymachine'
	--plain-text
		by default ipnotify send an html message use this flag to
		receive a simple plain text

	mail and passwd can't be specified by command line arguments because
	isn't safe, you must use the configuration file
EOF

opts.each do |option, arg|

	case option
	when '--help'
		puts(USAGE)
		exit(0)
	when '--daemon'
		cmd_opt[:daemon]   = true
		cmd_opt[:pidfile]  = arg.empty?() ? $opt[:pidfile] : File.absolute_path(arg.to_s)
	when '--log'
		cmd_opt[:logfile]  = arg.empty?() ? '/var/log/ipnotify.log' : File.absolute_path(arg.to_s)
	when '--cache'
		opt[:cachefile]    = arg.empty?() ? $opt[:cachefile] : File.absolute_path(arg.to_s)
	when '--config'
		cmd_opt[:cfgfile]  = arg.empty?() ? cmd_opt[:cfgfile] : File.absolute_path(arg.to_s)
	when '--hostname'
		cmd_opt[:hostname] = arg.empty?() ? $opt[:hostname] : arg.to_s
	when '--plain-text'
		cmd_opt[:textonly] = true
	else
		puts(USAGE)
		exit(1)
	end

end


if ((instances=`pgrep ipnotify`.split("\n")).length != 1)
	STDERR.puts("err ipnotify running as: #{instances[0]} only one instance at time is permitted")
	exit(3)
end


load cmd_opt[:cfgfile]

# destructive merge
$opt.update($cfg)
$opt.update(cmd_opt)

# check if certains required files can be created/written
[ :pidfile, :cachefile, :logfile ].each { |o|
	if ((errmsg=IOPerm::echeck($opt[o].to_s)))
		STDERR.puts("#{errmsg}")
		exit(4)
	end
}

# p $opt
# exit 0

if $opt[:mail].empty? || $opt[:passwd].empty?
	STDERR.puts("mail and passwd are required, -h for help")
	exit(2)
elsif $opt[:mail].scan(/[a-z].*@gmail\..*/)[0] == nil
	STDERR.puts("invalid argument \"#{$opt[:mail]}\" only gmail accounts are supported, -h for help")
	exit(3)
end



# 10 MB log
$logger = Logger.new($opt[:logfile], 0, 10485760)
$logger.datetime_format = '%d/%m/%Y %H:%M:%S'

# EXIT, INT, QUIT, TERM
[0,2,3,15].each { |sig|
	Signal.trap(sig) { $logger.close; exit }
}

# daemonize
if ($opt[:daemon])
	Process.daemon
	File.open($opt[:pidfile], File::TRUNC|File::RDWR|File::CREAT, 0644) { |f| f.puts($$) }
end


loop {

	if ((my_ip = get_ip()) != (prev = IPstore::load_from_cache($opt[:cachefile])))

		next if my_ip.empty?

		object = "#{$opt[:hostname]} #{prev} -> #{my_ip}"
		body   = $opt[:textonly] ? "#{my_ip}" : mail_body("#{$opt[:hostname]}", "#{my_ip}")

		if (!$opt[:daemon])
			puts("#{$opt[:mail]} #{$opt[:hostname]} #{my_ip} #{prev} => #{my_ip}")
		end

		$logger.info("\"#{prev}\" => \"#{my_ip}\"")

		if !sendgmail($opt[:textonly], "#{$opt[:mail]}", "#{$opt[:passwd]}", object, body)
			$logger.warn('sendgmail()') { "at line: #{__LINE__}" }
			STDERR.puts("sendgmail() failed") if (!$opt[:daemon])
		else
			IPstore::save_to_cache(my_ip, $opt[:cachefile])
		end

	end

	puts "your ip: #{my_ip}" if (!$opt[:daemon])
	sleep 1

}
