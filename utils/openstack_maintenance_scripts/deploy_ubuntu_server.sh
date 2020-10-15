if [ "$OS_PROJECT_ID" == "" ]
then
  echo
  echo "Please login to a project first (source the openrc files to set the environment variables)."
  echo
  exit 1
fi

if [ "$3" == "" ]
then
  echo
  echo "NOTE: You should use ./deploy_network_and_router.sh prior to using this script."
  echo
  echo "Usage: ./deploy_ubuntu_server.sh <hostname> <key name> <create floating ips yes/no> <server flavor>"
  echo
  echo "Description: This script creates one or more VMs based on the flavor definition (CPU and Memory definition),"
  echo "             images a volume with an operating system, attaches the volume as the boot device, connects the"
  echo "             network to the VM's port, assigns security groups to VM's port, injects the public key into the"
  echo "             image, and finally boots the server, resizing the boot partition to fill up the boot drive."
  echo
  echo "Example: ./deploy_test_ubuntu_servers.sh .ssh/id_rsa.pub yes 1 1 c5s.large 50 gp1"
  echo
  exit 1
fi

domain_region="us-central-1"
hostname=$1
key_name=$2
add_floating_ips=$3
server_flavor="$4"
server_flavor="${server_flavor:-t5sd.large}"
project_name="$OS_PROJECT_NAME"

network_name="network-1"
image_name="ubuntu-20.04-focal-minimal-cloudimg-amd64-release-20200501_raw"


echo "Creating the server..."
echo
results=$(openstack server create $hostname \
  --image $image_name \
  --flavor $server_flavor \
  --key-name $key_name \
  --network $network_name \
  --security-group AllowSSHInbound \
  --security-group AllowICMPInbound \
  --key-name $key_name)

echo
echo "Waiting for the creation of the server to finish..."
for INDEX in {1..200}
do
  status=$(openstack server show $hostname -f value -c status)

  echo "Status: $status"
  if [ "$status" == "ACTIVE" ]
  then break
  elif [ "$status" == "" ]
  then exit 1
  elif [ "$status" == "ERROR" ]
  then exit 1
  fi

  sleep 1
done

if [ "$add_floating_ips" == "yes" ]
then
  echo
  echo "Creating public IP..."
  server_public_ip=$(openstack floating ip create ext-net --tag $hostname -f value -c "floating_ip_address")

  echo
  echo "Assigning public IP to VM..."
  results=$(openstack server add floating ip $hostname $server_public_ip)

  echo
  echo -n "Waiting for a ping to respond from the server... "
  for INDEX in {1..100}
  do
    results=$(ping -c 1 -W 1 $server_public_ip)
    if [ "$?" == "0" ]
    then break;
    else echo -n "*"
    fi
  done

  echo
  echo
  echo "You may now SSH to the VM using this command:"
  echo "ssh -i <private key file> ubuntu@$server_public_ip"
fi

echo
echo "To view the console of the VM, browse to this URL (may take a minute before this is ready):"
source ./console.sh $hostname

echo
echo "To view the content displayed on the console of the VM while booting, use this command:"
echo "./boot_log.sh $hostname | less"

echo
echo "Done!"
echo
