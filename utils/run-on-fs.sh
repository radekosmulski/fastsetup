IP=`openstack server show fs -f shell -c addresses | tr -cd [[:digit:],[=.=]]`

rsync monit.sh ubuntu@$IP:/home/ubuntu/fastsetup
ssh ubuntu@$IP bash -e << EOF
  cd fastsetup
  MONIT_MAILSERVER_ADDRESS=$MONIT_MAILSERVER_ADDRESS MONIT_MAILSERVER_PORT=$MONIT_MAILSERVER_PORT \
  MONIT_MAILSERVER_USERNAME=$MONIT_MAILSERVER_USERNAME MONIT_MAILSERVER_PASSWORD=$MONIT_MAILSERVER_PASSWORD \
  MONIT_ALERT_ADDRESSEE=$MONIT_ALERT_ADDRESSEE source monit.sh
EOF
