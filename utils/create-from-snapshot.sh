# To run this, first create an image, for instance as belo
# openstack server image create fs --name <name>

IMAGE_NAME=fs_after_dotfiles

openstack server create fs --image $IMAGE_NAME --flavor t5sd.large --key-name $SSH_KEY_NAME --wait
IP=`openstack server show fs -f shell -c addresses | tr -cd [[:digit:],[=.=]]`

sleep 20
