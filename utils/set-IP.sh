result=`openstack server show $NEWHOST -f shell -c addresses | tr -cd [[:digit:],[=.=]]`
IP=${result: -13}
