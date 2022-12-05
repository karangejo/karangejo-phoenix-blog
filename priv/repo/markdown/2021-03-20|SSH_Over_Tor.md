Have you ever needed access to a home or work computer through ssh but you just don't have public IP and are not able to set one up for whatever reason.

I will show ou how to set up ssh over the TOR network giving you an onion address to ssh into instead of a public IP!

## Server Setup

First lets set up the server. Run the following in a terminal:

```bash
sudo apt-get install tor
sudo apt-get install openssh-server
```

next we have to make a hidden service directory and change its permissions:

```bash
sudo mkdir /var/lib/tor/torssh
sudo chown -R debian-tor /var/lib/tor/torssh
sudo chmod 0700 /var/lib/tor/torssh
```

Next we have to configure tor so add these lines to /etc/tor/torrc:

```bash
HiddenServiceDir /var/lib/tor/torssh/
HiddenServicePort 22 127.0.0.1:22
HiddenServiceAuthorizeClient stealth torssh
```

Then add this line to ~/.ssh/config

```bash
ListenAddress 127.0.0.1
```

Finally restart all the services so that our changes can take effect:

```bash
service tor restart
service ssh restart
```

Take note of the changes made to the file /var/lib/tor/torssh/hostname. Save this hotname for later

OK! your host is up and running and you now have an onion address with an ssh service running over it. Congratulations! But how do we connect to it?

## Client Setup

First install packages some required packages:

```bash
sudo apt-get install tor
sudo apt-get install openssh-client
```

For the next two parts you will need the hostname you got from when you set up the server. Add these lines to ~/.ssh/config:

```bash
host hidden
  hostname $REPLACE_WITH_HOSTNAME_FROM_SERVER
  proxyCommand torsocks nc %h %p
```

Next add this line to /etc/tor/torrc:

```bash
HidServAuth $REPLACE_WITH_HOSTNAME_AND_AUTH_STRING_FROM_SERVER
```

Finally start tor service by running tor and connect with the following command:

```bash
tor
ssh hidden
```

You can also start a vnc session over tor! (ssh might need an -l user if remote user is different) I wouldn't reccomend it though. Better just stick to ssh. But if you insist, here you go:

```bash
ssh -L 6000:localhost:5900 hidden env DISPLAY=:0 x11vnc -localhost
```

You may have noticed that this connection is kind of slow because it runs over tor. Not ideal for all use cases but can definitely be a solution to certain situations. Enjoy!

You can also check out my [git hub repo](https://github.com/karangejo/ssh-over-tor) with all the commands found on this page.

For more info please refer to:  
https://www.torproject.org/  
https://www.ssh.com/ssh/
