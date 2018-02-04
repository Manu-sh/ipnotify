# ipnotify
######  notify to your gmail account when public ip address change 


### Installation
You can also install ipnotify as normal user (and maybe is a better choice)
but isn't covered by this readme.

```bash
git clone https://github.com/Manu-sh/ipnotify
sudo gem install gmail
cd ipnotify

# ensure that all files have correct permissions
chmod 0744 .
chmod 0600 ipnotify.*
chmod 0644 *.rb
chmod 0755 ipnotify.rb

# now as root
cp -r ../ipnotify /opt

# install the configuration file
mv -v /opt/ipnotify/ipnotify.cfg /etc

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
```

## Configuration
Edit *ipnotify.cfg* and setting your mail address and password,
some command line options like `--hostname` can be specificated also
throught the configuration file, to get more details on these common options
type:

`/opt/ipnotify/ipnotify.rb -h`

now you should be able enable & start the service
```
sudo systemctl enable ipnotify.service
sudo systemctl start ipnotify.service
```

###### Copyright © 2018, [Manu-sh](https://github.com/Manu-sh), s3gmentationfault@gmail.com. Released under the [GPL3 license](LICENSE).
