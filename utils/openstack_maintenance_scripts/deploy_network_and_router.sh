if [ "$OS_PROJECT_ID" == "" ]
then
  echo
  echo "Please login to a project first (source the openrc files to set the environment variables)."
  echo
  exit 1
fi

if [ "$1" != "--yes-i-really-really-mean-it" ]
then
  echo
  echo "Usage: ./deploy_network_and_router.sh --yes-i-really-really-mean-it"
  echo
  echo "Description: Deploys a test router, network, subnet, and four security groups,"
  echo "             for SSH, HTTP, HTTPS, and ICMP inbound, in preparation for"
  echo "             the deploy_ubuntu_server.sh script."
  echo
  echo "MUST include --yes-i-really-really-mean-it"
  echo
  exit 1
fi

domain_region="us-central-1"
router_name="router-1"
network_name="network-1"
subnet_name="subnet-1"
subnet_range="192.168.99.0/24"
subnet_gateway="192.168.99.254"
subnet_pool_start="192.168.99.1"
subnet_pool_end="192.168.99.253"
project_id="$OS_PROJECT_ID"
project_name="$OS_PROJECT_NAME"

echo
echo "Creating the router..."
results=$(openstack router create "$router_name")

echo
echo "Connecting the router's uplink port to the external bridge at Genesis"
results=$(openstack router set --external-gateway ext-net "$router_name")

# Create a tenant network where VMs will be connected as well as a connection to the router
echo
echo "Creating a managed layer 2 network with an MTU of 1500"
results=$(openstack network create --mtu 1500 "$network_name")

echo
echo "Creating a managed layer 3 subnet (OpenStack manages the IPs) and a DHCP server"
echo "on the layer 2 network we just created..."
results=$(openstack subnet create \
  --network $network_name \
  --subnet-range $subnet_range \
  --gateway $subnet_gateway \
  --dns-nameserver 1.1.1.1 \
  --dns-nameserver 8.8.8.8 \
  --dns-nameserver 8.8.4.4 \
  --allocation-pool start=$subnet_pool_start,end=$subnet_pool_end \
  "$subnet_name")


echo
echo "Connect the subnet to the router, which creates a port on the router and"
echo "connects the network to this port."
results=$(openstack router add subnet "$router_name" "$subnet_name")

echo
echo "Security groups are ACLs assigned to a port, which can be a router port,"
echo "a VM port, etc.  The name \"port\" is the same as \"interface\"."
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
echo "Create a security group with a rule to allow ICMP inbound..."
results=$(openstack security group create AllowICMPInbound)
results=$(openstack security group rule create \
  --remote-ip 0.0.0.0/0 \
  --ingress \
  --protocol icmp \
  AllowICMPInbound)

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

echo
echo "Done!"
echo

echo
echo "To view all of the objects we just created, use the following commands:"
echo "openstack router list"
echo "openstack router show <router id or name>"
echo "openstack network list"
echo "openstack network show <network id or name>"
echo "openstack subnet list"
echo "openstack subnet show <subnet id or name>"
echo "openstack security group list"
echo "openstack security group show <security group id or name>"
echo "openstack security group rule list"
echo "openstack security group rule list <security group id or name>"
echo
echo "For help with any of the commands, including options available, add --help to the command."
echo


