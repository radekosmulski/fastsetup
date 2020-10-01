# This script installs monit and configures it for system monitoring.
# You can use the environment_template.sh to set the necessary variables.
#
# The configuration below includes default values for loadavg that are likely to make sense
# for a single vCPU vm. If you are planning on using a vm that will have access to a higher
# number of vCPUs, please adjust the values accordingly.

set -e

for VARIABLE in "$MONIT_MAILSERVER_ADDRESS" "$MONIT_MAILSERVER_PORT" "$MONIT_MAILSERVER_USERNAME" "$MONIT_MAILSERVER_PASSWORD" "$MONIT_ALERT_ADDRESSEE" "$MONIT_ALERT_SENDER"
do
  if [[ -z "$VARIABLE" ]]; then
    echo 'Please make sure you set all the needed environmental variables (consult monit.sh for more information)'
    exit 1
  fi
done

echo pass | sudo -S apt-get install -y monit

sudo perl -p -i -e 's/set daemon 120/set daemon 30/' /etc/monit/monitrc
sudo perl -p -i -e 's/#   with start delay 240/  with start delay 60/' /etc/monit/monitrc

sudo tee -a /etc/monit/monitrc > /dev/null << EOF
  set mailserver $MONIT_MAILSERVER_ADDRESS port $MONIT_MAILSERVER_PORT
     username "$MONIT_MAILSERVER_USERNAME" password "$MONIT_MAILSERVER_PASSWORD"
     using AUTO with timeout 30 seconds
  set alert $MONIT_ALERT_ADDRESSEE but not on {instance, pid}
  set mail-format { from: $MONIT_ALERT_SENDER }
EOF

sudo tee /etc/monit/conf.d/system.conf > /dev/null << \EOF
  check system $HOST
    if loadavg (1min) > 0.9 then alert
    if loadavg (5min) > 0.75 then alert
    if memory usage > 75% then alert
    if cpu usage (user) > 70% for 5 cycles then alert
    if cpu usage (system) > 30% for 5 cycles then alert
    if cpu usage (wait) > 20% for 5 cycles then alert

    check filesystem rootfs with path /
      if space usage > 80% then alert
EOF

sudo monit reload
