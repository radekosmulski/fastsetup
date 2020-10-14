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

echo
echo "Create a security group with a rule to allow SSH inbound..."
results=$(openstack security group create AllowSSHInbound)
results=$(openstack security group rule create \
  --remote-ip 0.0.0.0/0 \
  --dst-port 22 \
  --ingress \
  --protocol tcp \
  AllowSSHInbound)

echo
echo "Create a security group with a rule to allow HTTP inbound..."
results=$(openstack security group create AllowHTTPInbound)
results=$(openstack security group rule create \
  --remote-ip 0.0.0.0/0 \
  --dst-port 80 \
  --ingress \
  --protocol tcp \
  AllowHTTPInbound)

echo
echo "Create a security group with a rule to allow HTTPS inbound..."
results=$(openstack security group create AllowHTTPSInbound)
results=$(openstack security group rule create \
  --remote-ip 0.0.0.0/0 \
  --dst-port 443 \
  --ingress \
  --protocol tcp \
  AllowHTTPSInbound)

# Create instance
IP=$(openstack server create $NEWHOST \
  --image ubuntu-20.04_LTS-focal-server-cloudimg-amd64-20200227_raw \
  --flavor t5sd.large \
  --key-name $SSH_KEY_NAME \
  --network ext-net-no-nat \
  --security-group AllowSSHInbound \
  --security-group AllowHTTPInbound \
  --security-group AllowHTTPSInbound \
  --wait -c addresses -f value | cut -sd '=' -f 2)

# Perform fastsetup
sleep 30
source ./perform-fastsetup.sh
