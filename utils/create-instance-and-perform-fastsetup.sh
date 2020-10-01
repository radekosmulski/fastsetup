# This script uses the openstack api. It was developed to work with https://www.genesishosting.com/.
#
# What are it's uses? It allows you to document and retain the configuration steps for creating
# an instance. All you have to do is to retain the template  you used to configure
# the instance (for a starting point please see instance_templates/default.sh).
#
# Further to that, I use this script to help me test fastsetup. It is also very helpful when you
# want to work on additions / modifications, especially if you use the snapshotting functionality
# available through the openstack CLI.

set -e

for VARIABLE in "$SSH_KEY_NAME" "$INSTALL_MONIT" "$NEWPASS" "$GIT_NAME" "$GIT_EMAIL"
do
  if [[ -z "$VARIABLE" ]]; then
    echo Please make sure you set all the needed environmental variables
    exit 1
  fi
done

function fail() { echo $1 ; exit 1 ; }

# Create instance
openstack server create fs --image ubuntu-20.04-focal-minimal-cloudimg-amd64-release-20200501_raw --flavor t5sd.large --key-name $SSH_KEY_NAME --wait
IP=`openstack server show fs -f shell -c addresses | tr -cd [[:digit:],[=.=]]`

# Perform fastsetup
sleep 15
ssh ubuntu@$IP bash -e << EOF || fail "Failed to clone fastsetup"
  sudo apt update && sudo apt -y install git
  git clone https://github.com/radekosmulski/fastsetup.git
EOF

ssh ubuntu@$IP bash -e << EOF || fail "Failed to run 'sudo ./ubuntu-initial.sh'"
  cd fastsetup
  sudo NEWPASS=$NEWPASS REBOOT=false ./ubuntu-initial.sh
EOF

ssh ubuntu@$IP bash -e << EOF || fail "Issue running sudo as user ubuntu"
  echo $NEWPASS | sudo -S shutdown -r now
EOF

echo -e '\nDisconnected from vm and reconnecting over SSH'
sleep 10

ssh ubuntu@$IP bash -e << EOF || fail "Sourcing dotfiles.sh failed"
  cd fastsetup
  GIT_NAME="$GIT_NAME" GIT_EMAIL=$GIT_EMAIL source dotfiles.sh

EOF

if [ "$INSTALL_MONIT" = true ] ; then
ssh ubuntu@$IP bash -e << EOF || fail "Setting up monit failed"
  cd fastsetup
  MONIT_MAILSERVER_ADDRESS=$MONIT_MAILSERVER_ADDRESS MONIT_MAILSERVER_PORT=$MONIT_MAILSERVER_PORT \
  MONIT_MAILSERVER_USERNAME=$MONIT_MAILSERVER_USERNAME MONIT_MAILSERVER_PASSWORD=$MONIT_MAILSERVER_PASSWORD \
  MONIT_ALERT_ADDRESSEE=$MONIT_ALERT_ADDRESSEE MONIT_ALERT_SENDER=$MONIT_ALERT_SENDER source monit.sh
EOF
fi

ssh ubuntu@$IP bash -e << EOF || fail "Installing fail2ban failed"
  echo $NEWPASS | sudo -S apt install -y fail2ban
EOF

# Remove instance
#openstack server delete fs
