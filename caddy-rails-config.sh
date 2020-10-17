DOMAIN=$(hostname -d)
perl -pi -e "s/DOMAIN/$DOMAIN/g" Caddyfile-rails
perl -pi -e "s/APPNAME/$CADDY_APPNAME/g" Caddyfile-rails
echo $NEWPASS | sudo -k -S cp Caddyfile-rails /etc/caddy/Caddyfile
echo $NEWPASS | sudo -k -S systemctl reload caddy
