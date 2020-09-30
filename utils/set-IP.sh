IP=`openstack server show fs -f shell -c addresses | tr -cd [[:digit:],[=.=]]`
