
### Dependencies
sudo gem install gmail

### Installation
git clone ...
cd ipnotify

# ensure that all files have correct permissions
chmod 0744 .
chmod 0600 ipnotify.*
chmod 0644 *.rb
chmod 0755 ipnotify.rb

sudo cp -rfv ../ipnotify /opt

# install the configuration file
mv -fv /opt/ipnotify/ipnotify.cfg /etc

# create the relative service
cat > /etc/systemd/system/ipnotify.service << EOF
[Unit]
Description=notify to your gmail account when your public ip address change
After=network.target

[Service]
User=root
PIDFile=/var/run/ipnotify.pid
Type=forking
ExecStart=/opt/ipnotify/ipnotify.rb -d

ProtectKernelTunables=yes
ProtectKernelModules=yes

[Install]
WantedBy=multi-user.target
EOF

## Configuration
now you should edit ipnotify.cfg setting your mail address and password,
some command line options like --hostname can be specificated also
throught the configuration file, to get more details of those common options
type:

`/opt/ipnotify/ipnotify.rb -h`

now you should be able enable & start the service
```
sudo systemctl enable ipnotify.service
sudo systemctl start ipnotify.service
```
