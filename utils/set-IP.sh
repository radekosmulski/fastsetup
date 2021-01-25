result=`openstack server show $NEWHOST -f shell -c addresses | tr -cd [[:digit:],[=.=]]`
result=${result: -14}
export IP=${result#*,}
