# This script uses the openstack api. It was developed to work with https://www.genesishosting.com/.
#
# What are it's uses? It allows you to document and retain the configuration steps for creating
# an instance. All you have to do is to retain the template  you used to configure
# the instance (for a starting point please see instance_templates/default.sh).
#
# Further to that, I use this script to help me test fastsetup. It is also very helpful when you
# want to work on additions / modifications, especially if you use the snapshotting functionality
# available through the openstack CLI.

for VARIABLE in "$IP" "$SSH_KEY_NAME" "$NEWHOST" "$NEWPASS" "$GIT_NAME" "$GIT_EMAIL" \
  "$INSTALL_MONIT" "$EMAIL" "$AUTO_REBOOT"
do
  if [[ -z "$VARIABLE" ]]; then
    echo Please make sure you set all the needed environmental variables
    exit 1
  fi
done

fail () { echo $1 >&2; exit 1; }

# Perform fastsetup
ssh ubuntu@$IP bash -e << EOF || fail "Failed to clone fastsetup"
  sudo apt update && sudo apt -y install git
  git clone https://github.com/radekosmulski/fastsetup.git
  cd fastsetup
  sudo cp 01-netcfg.yaml /etc/netplan
EOF

ssh ubuntu@$IP bash -e << EOF || fail "Failed to run 'sudo ./ubuntu-initial.sh'"
  cd fastsetup
  sudo NEWHOST=$NEWHOST NEWPASS=$NEWPASS EMAIL=$EMAIL AUTO_REBOOT=$AUTO_REBOOT REBOOT=false ./ubuntu-initial.sh
EOF

ssh ubuntu@$IP bash -e << EOF || fail "Issue running sudo as user ubuntu"
  echo $NEWPASS | sudo -S shutdown -r now
EOF

echo -e '\nDisconnected from vm and reconnecting over SSH'
sleep 30

ssh ubuntu@$IP bash -e << EOF || fail "Sourcing dotfiles.sh failed"
  cd fastsetup
  NAME="$GIT_NAME" EMAIL=$GIT_EMAIL source dotfiles.sh

EOF

if [ "$INSTALL_OPENSMTPD" = true ] ; then
ssh ubuntu@$IP bash -e << EOF || fail "Running 'sudo opensmtpd-install.sh' failed"
  cd fastsetup
  echo $NEWPASS | sudo -S apt install -y dnsutils
  sudo ROOTMAIL=$ROOTMAIL SMTPPASS=$SMTPPASS ./opensmtpd-install.sh
EOF
fi

if [ "$INSTALL_RAILS" = true ] ; then
ssh ubuntu@$IP bash -e << EOF || fail "Installing rails failed"
  cd fastsetup
  NEWPASS=$NEWPASS RUBY_VERSION=$RUBY_VERSION ./rails-install.sh
EOF
fi

if [ "$INSTALL_CADDY" = true ] ; then
if ! openstack server show $NEWHOST | grep -q 'AllowHTTPInbound'; then
  openstack server add security group $NEWHOST AllowHTTPInbound
fi
if ! openstack server show $NEWHOST | grep -q 'AllowHTTPSInbound'; then
  openstack server add security group $NEWHOST AllowHTTPSInbound
fi

ssh ubuntu@$IP bash -e << EOF || fail "Installing caddy failed"
  cd fastsetup
  NEWPASS=$NEWPASS ./caddy-install.sh
  NEWPASS=$NEWPASS CADDY_APPNAME=$CADDY_APPNAME IP=$IP ./caddy-rails-config.sh
EOF
fi

ssh ubuntu@$IP bash -e << EOF || fail "Installing fail2ban failed"
  echo $NEWPASS | sudo -S apt install -y fail2ban
EOF

if [ "$INSTALL_MONIT" = true ] ; then
ssh ubuntu@$IP bash -e << EOF || fail "Setting up monit failed"
  cd fastsetup
  NEWPASS=$NEWPASS MONIT_MAILSERVER_ADDRESS=$MONIT_MAILSERVER_ADDRESS MONIT_MAILSERVER_PORT=$MONIT_MAILSERVER_PORT \
  MONIT_MAILSERVER_USERNAME=$MONIT_MAILSERVER_USERNAME MONIT_MAILSERVER_PASSWORD=$MONIT_MAILSERVER_PASSWORD \
  MONIT_ALERT_ADDRESSEE=$MONIT_ALERT_ADDRESSEE MONIT_ALERT_SENDER=$MONIT_ALERT_SENDER source monit.sh
EOF
fi
