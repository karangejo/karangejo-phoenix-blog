This is a short guide on setting up Nginx first for http and then for https. First we need a basic setup so create the file /etc/nginx/conf.d/yourdomain.com.conf with:

```bash
vim /etc/nginx/conf.d/yourdomain.com.conf
```

And add the followinf lines to it:

```bash
server {
   server_name yourdomain.com;
   listen 80;
   root /home/yourAppDirectory/build/;

   index index.html index.htm;
   location / {
   try_files $uri /index.html =404;
   }
```

Ok now we need to check if everything is ok and then restart nginx:

```bash
nginx -t
sudo systemctl restart nginx.service
```

If everything went well then we can now make the switch to https! First install [certbot](https://certbot.eff.org/):

```bash
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install python-certbot-nginx
```

Then run the following:

```bash
sudo certbot --nginx -d yourdomain.com
```

When it asks you if you want to redirect answer that yes you do want to redirect to https.

Now if you check your /etc/nginx/conf.d/yourdomain.com.conf file you will see this:

```bash
server {
   server_name yourdomain.com;
   root /home/yourAppDirectory/build/;

   index index.html index.htm;
   location / {
   try_files $uri /index.html =404;
   }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/yourdomain/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}
server {
    if ($host = yourdomain.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

   server_name yourdomain.com;
    listen 80;
    return 404; # managed by Certbot
}
```

Certbot has automatically added these lines and now anyone who visits your site will be redirected through https!
