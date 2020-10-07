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
  echo "Usage: destroy_network_and_router.sh --yes-i-really-really-mean-it"
  echo
  echo "MUST include --yes-i-really-really-mean-it"
  echo
  exit 1
fi

domain_region="us-central-1"
router_name="router-1"
network_name="network-1"
subnet_name="subnet-1"
project_id="$OS_PROJECT_ID"
project_name="$OS_PROJECT_NAME"

echo
echo "Removing subnets and ports from routers..."
routers=$(openstack router list --name "$router_name" -f value -c ID)
for UUID in $routers
do
  router_subnets=$(openstack port list --router $UUID -f json | jq '.[]."Fixed IP Addresses"[]."subnet_id"' | sed 's/\"//g' | uniq)
  for UUID2 in $router_subnets
  do
    echo "- Removing router subnet "$UUID2
    results=$(openstack router remove subnet $UUID $UUID2)
  done

  router_ports=$(openstack port list --router $UUID -f json | jq '.[].ID' | sed 's/\"//g' | uniq)
  for UUID2 in $router_ports
  do
    echo "- Removing router port "$UUID2
    results=$(openstack router remove port $UUID $UUID2)
  done
done

echo
echo "Removing routers..."
for UUID in $routers
do
  echo "- Removing router "$UUID
  results=$(openstack router delete $UUID)
done


echo
echo "Removing ports associated with subnets..."
subnets=$(openstack subnet list --name "$subnet_name" -f value -c ID)
for UUID in $subnets
do
  ports=$(openstack port list | awk "/$UUID/ { print \$2 }")
  for UUID2 in $ports
  do
    echo "- Removing subnet port $UUID2"
    results=$(openstack port delete $UUID2)
  done
done

echo
echo "Removing subnets..."
for UUID in $subnets
do
  echo "- Removing subnet "$UUID
  results=$(openstack subnet delete $UUID)
done


echo
echo "Removing networks..."
networks=$(openstack network list --name "$network_name" -f value -c ID)
for UUID in $networks
do
  echo "- Removing network "$UUID
  results=$(openstack network delete $UUID)
done


echo
echo "Removing security group AllowSSHInbound..."
securitygroups=$(openstack security group list | awk "/ AllowSSHInbound / { print \$2 }")
for UUID in $securitygroups
do
  echo "- Removing security group "$UUID
  results=$(openstack security group delete $UUID)
done

echo
echo "Removing security group AllowICMPInbound..."
securitygroups=$(openstack security group list | awk "/ AllowICMPInbound / { print \$2 }")
for UUID in $securitygroups
do
  echo "- Removing security group "$UUID
  results=$(openstack security group delete $UUID)
done

echo
echo "Removing security group AllowHTTPInbound..."
securitygroups=$(openstack security group list | awk "/ AllowHTTPInbound / { print \$2 }")
for UUID in $securitygroups
do
  echo "- Removing security group "$UUID
  results=$(openstack security group delete $UUID)
done

echo
echo "Removing security group AllowHTTPSInbound..."
securitygroups=$(openstack security group list | awk "/ AllowHTTPSInbound / { print \$2 }")
for UUID in $securitygroups
do
  echo "- Removing security group "$UUID
  results=$(openstack security group delete $UUID)
done

echo
echo "Done!"
echo

