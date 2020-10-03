# This script uses the openstack api. It was developed to work with https://www.genesishosting.com/.
#
# What are it's uses? It allows you to document and retain the configuration steps for creating
# an instance. All you have to do is to retain the template  you used to configure
# the instance (for a starting point please see instance_templates/default.sh).
#
# Further to that, I use this script to help me test fastsetup. It is also very helpful when you
# want to work on additions / modifications, especially if you use the snapshotting functionality
# available through the openstack CLI.

for VARIABLE in "$SSH_KEY_NAME" "$NEWHOST" "$NEWPASS" "$GIT_NAME" "$GIT_EMAIL" "$INSTALL_MONIT" \
  "$EMAIL" "$AUTO_REBOOT"
do
  if [[ -z "$VARIABLE" ]]; then
    echo Please make sure you set all the needed environmental variables
    exit 1
  fi
done

fail () { echo $1 >&2; exit 1; }

# Create instance
IP=$(openstack server create $NEWHOST --image ubuntu-20.04_LTS-focal-server-cloudimg-amd64-20200227_raw --flavor t5sd.large --key-name $SSH_KEY_NAME --wait -c addresses -f value | cut -sd '=' -f 2)

# Perform fastsetup
sleep 25
ssh ubuntu@$IP bash -e << EOF || fail "Failed to clone fastsetup"
  sudo apt update && sudo apt -y install git
  git clone https://github.com/radekosmulski/fastsetup.git
EOF

ssh ubuntu@$IP bash -e << EOF || fail "Failed to run 'sudo ./ubuntu-initial.sh'"
  cd fastsetup
  sudo NEWHOST=$NEWHOST NEWPASS=$NEWPASS EMAIL=$EMAIL AUTO_REBOOT=$AUTO_REBOOT REBOOT=false ./ubuntu-initial.sh
EOF

ssh ubuntu@$IP bash -e << EOF || fail "Issue running sudo as user ubuntu"
  echo $NEWPASS | sudo -S shutdown -r now
EOF

echo -e '\nDisconnected from vm and reconnecting over SSH'
sleep 10

ssh ubuntu@$IP bash -e << EOF || fail "Sourcing dotfiles.sh failed"
  cd fastsetup
  NAME="$GIT_NAME" EMAIL=$GIT_EMAIL source dotfiles.sh

EOF

if [ "$INSTALL_OPENSMTPD" = true ] ; then
ssh ubuntu@$IP bash -e << EOF || fail "Running 'sudo opensmtpd-install.sh' failed"
  echo $NEWPASS | sudo -S ROOTMAIL=$ROOTMAIL SMTPPASS=$SMTPPASS ./opensmtpd-install.sh
EOF
fi

if [ "$INSTALL_MONIT" = true ] ; then
ssh ubuntu@$IP bash -e << EOF || fail "Setting up monit failed"
  cd fastsetup
  NEWPASS=$NEWPASS MONIT_MAILSERVER_ADDRESS=$MONIT_MAILSERVER_ADDRESS MONIT_MAILSERVER_PORT=$MONIT_MAILSERVER_PORT \
  MONIT_MAILSERVER_USERNAME=$MONIT_MAILSERVER_USERNAME MONIT_MAILSERVER_PASSWORD=$MONIT_MAILSERVER_PASSWORD \
  MONIT_ALERT_ADDRESSEE=$MONIT_ALERT_ADDRESSEE MONIT_ALERT_SENDER=$MONIT_ALERT_SENDER source monit.sh
EOF
fi

ssh ubuntu@$IP bash -e << EOF || fail "Installing fail2ban failed"
  echo $NEWPASS | sudo -S apt install -y fail2ban
EOF

# Remove instance
#openstack server delete fs
