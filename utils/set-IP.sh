result=`openstack server show $NEWHOST -f shell -c addresses | tr -cd [[:digit:],[=.=]]`
result=${result: -13}
IP=${result//,}
