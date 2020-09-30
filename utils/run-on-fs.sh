IP=`openstack server show fs -f shell -c addresses | tr -cd [[:digit:],[=.=]]`

# you can send files the remote host using the following command
# rsync <file_path> ubuntu@$IP:<target_directory>

ssh ubuntu@$IP bash -e << EOF
  echo Type commands here you would like executed on remote host
EOF
