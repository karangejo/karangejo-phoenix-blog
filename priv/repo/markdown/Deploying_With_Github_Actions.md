I decided it was about time I took a look into github actions. Everyone says it can replace your CI/CD pipeline. So I checked it out and came up with this simple workflow that works for my simple self hosted projects.

If you are like me and ssh into your VPS and set everything up manually (git cloning, building, setting up Apache or Nginx and finally certbot) then you will appreciate being able to deploy with a simple push to master (or maybe a deploy branch). 

I started adding some version of this workflow to my repos once I know my application is running pretty smoothly. I can then make local changes push them and they are automatically deployed.

Here is the script:


```yaml
name: Deploy Posts
# runs on push to master
on:
  push:
    branches: [master]
jobs:
  deploy:
    name: deploy_over_ssh
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      # Copies local folder to the remote server
      - uses: garygrossgarten/github-action-scp@release
        with:
          local: ./local-folder/
          remote: /remote/folder/
          host: ${{ secrets.SERVER_IP }}
          username: ${{ secrets.SERVER_USER_NAME }}
          password: ${{ secrets.SERVER_PASS }}
      # Goes to the remote folder, installs dependencies, and builds the app 
      - uses: garygrossgarten/github-action-ssh@v0.5.0
        with:
          command: cd /remote-folder/ ; npm install ; npm build
          host: ${{ secrets.SERVER_IP }}
          username: ${{ secrets.SERVER_USER_NAME }}
          password: ${{ secrets.SERVER_PASS }}
```

You will need to store your server_ip, username and password in the secrets section in the settings of your github repo. You will also need to specify the folders or files you want to copy over and the commands to be run on the remote server.

For more information check out:  
https://github.com/garygrossgarten/github-action-ssh  
https://github.com/garygrossgarten/github-action-scp