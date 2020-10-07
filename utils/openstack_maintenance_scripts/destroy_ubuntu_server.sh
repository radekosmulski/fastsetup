if [ "$OS_PROJECT_ID" == "" ]
then
  echo
  echo "Please login to a project first (source the openrc files to set the environment variables)."
  echo
  exit 1
fi

if [ "$3" != "--yes-i-really-really-mean-it" ]
then
  echo
echo "Usage: ./destroy_test_ubuntu_servers.sh <hostname> <remove floating ip yes/no> --yes-i-really-really-mean-it"
  echo
  echo "Description: Looping through each server name, deleting the server first, and then its volume."
  echo "             Note that if there are multiple servers with the same name, all servers by that"
  echo "             name will be deleted."
  echo
  echo "MUST include --yes-i-really-really-mean-it"
  echo
  exit 1
fi

hostname=$1
remove_floating_ips=$2
project_id="$OS_PROJECT_ID"
project_name="$OS_PROJECT_NAME"

server_uuids=$(openstack server list --name "$hostname" -f value -c ID)
for UUID in $server_uuids
do
  if [ "$remove_floating_ips" == "yes" ]
  then
    echo
    echo "Removing floating IP from server $server_name_prefix$ServerIndex..."
    floating_ip=$(openstack floating ip list --tags "$hostname" -f value -c ID)
    openstack server remove floating ip "$hostname" $floating_ip

    echo
    echo "Deleting floating IP..."
    openstack floating ip delete $floating_ip
  fi

  echo
  echo "Deleting server $hostname..."
  results=$(openstack server delete $UUID)
done

echo
echo "Done!"
echo
