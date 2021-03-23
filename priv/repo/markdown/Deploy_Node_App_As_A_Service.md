I have been deploying my backend APIs with [PM2](https://pm2.keymetrics.io/) for a while now. I noticed that when my server had to be rebooted (for maintenance or any other reason) the PM2 processes would not automatically restart on boot. So what is the point really? Ok, maybe there is a way to do this with PM2 but i made the switch to running my APIs as services in the linux OS itself. If you want to try it just keep reading.

First, create the file /etc/systemd/system/myapp.service:
```bash
sudo vim /etc/systemd/system/myapp.service 
```
Then you need to add the following to the file:
```bash
[Unit]
Description=Your app
After=network.target
[Service]
ExecStart=/var/www/myapp/myapp.js
Restart=always
User=nobody
# Use 'nogroup' group for Ubuntu/Debian
# use 'nobody' group for Fedora
Group=nogroup
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
WorkingDirectory=/var/www/myapp
[Install]
WantedBy=multi-user.target
```
You might need to change the Group and you will need to change the path to your app and the working directory.

After that you need to add this line to the top of your node app:
```javascript
#!/usr/bin/env/ node
```
You may also need to fix the line endings with:
```bash
vi myapp.js
:set ff=unix
```
Next change the permissions of your app to allow execution as a script with:
```
chmod +x myapp.js
```
Now you can run the following commands to enable your service on boot and start it up:
```bash
sudo systemctl daemon-reload
sudo systemctl enable myapp.service
sudo systemctl start myapp.service
sudo systemctl status myapp.service
```
Ok! We are all set up and if everything went well that last command should have printed out some good news. You can check the status of all ports currently open and running with:
```bash
sudo netstat -tupln
```
You should see your node app running on the correct port (if it is a server)