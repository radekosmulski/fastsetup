{ echo "$NEWPASS"; echo "deb [trusted=yes] https://apt.fury.io/caddy/ /"; } | sudo -k -S tee -a /etc/apt/sources.list.d/caddy-fury.list
echo $NEWPASS | sudo -k -S apt update
echo $NEWPASS | sudo -k -S apt install -y caddy
echo $NEWPASS | sudo -k -S ufw allow http
echo $NEWPASS | sudo -k -S ufw allow https
