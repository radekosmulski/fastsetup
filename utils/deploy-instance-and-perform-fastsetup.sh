# This script uses the openstack api. It was developed to work with https://www.genesishosting.com/.
#
# I use this script to help me test fastsetup. This is also a good way of automating the setup
# if we want to work on additions. I deploy and configure the instance using this script,
# then create a snapshot and can quickly revert back to the state before I started introducing changes.

set -e

if [[ -z "$SSH_KEY_NAME" ]]; then
  echo 'Please set the $SSH_KEY_NAME'
  exit 1
fi

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
  sudo NEWPASS=pass REBOOT=false ./ubuntu-initial.sh
EOF

ssh ubuntu@$IP bash -e << EOF || fail "Issue running sudo as user ubuntu"
  echo pass | sudo -S shutdown -r now
EOF

echo -e '\nDisconnected from vm and reconnecting over SSH'
sleep 10

ssh ubuntu@$IP bash -e << EOF || fail "Sourcing dotfiles.sh failed"
  cd fastsetup
  NAME="Test Name" EMAIL="test@test.com" source dotfiles.sh

EOF

ssh ubuntu@$IP bash -e << EOF || fail "Setting up monit failed"
  cd fastsetup
  MONIT_MAILSERVER_ADDRESS=$MONIT_MAILSERVER_ADDRESS MONIT_MAILSERVER_PORT=$MONIT_MAILSERVER_PORT \
  MONIT_MAILSERVER_USERNAME=$MONIT_MAILSERVER_USERNAME MONIT_MAILSERVER_PASSWORD=$MONIT_MAILSERVER_PASSWORD \
  MONIT_ALERT_ADDRESSEE=$MONIT_ALERT_ADDRESSEE source monit.sh
EOF

# Remove instance
#openstack server delete fs