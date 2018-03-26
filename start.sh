#!/bin/bash

ACCESS_KEY=XKA4C2Q
SECRET_KEY=aOkq5x0DDcmzADJx4mXx
MYSQL_PASS=mypass
WORDPRESS_USER=wordpressuser
WORDPRESS_DB=wordpress
WORDPRESS_PASS=wordpress
JUMP_HOST_IP=$(ip a |grep " inet "|grep -v 127|cut -d" " -f 6|cut -d'/' -f1)

print_logs () {
	echo "########################################################"
	echo " "
	echo $1
	echo " "
	echo "########################################################"
}

##################################################################
############################START
##################################################################

	print_logs "Start system update and install additional applications" 
apt-get update -y
apt-get install python python-pip curl -y
apt-get update -y
curl -O https://bootstrap.pypa.io/get-pip.py
python get-pip.py --user
export PATH=~/.local/bin:$PATH
chmod +x ~/.profile
~/.profile
chmod -x ~/.profile
source ~/.profile
pip install awscli --upgrade --user
my_id=$(whoami)
mkdir -p ~/.aws
apt install awscli -y
	print_logs " Finished with system update and application install" 

	print_logs "Adding AWS ACCESS_KEY and SECRET_KEY to config"
echo "[default]
aws_access_key_id = $ACCESS_KEY
aws_secret_access_key = $SECRET_KEY" > ~/.aws/credentials

echo "[default]
output = json
region = eu-west-1" > ~/.aws/config
	print_logs "Keys added"

	print_logs "Creating security group and provide access to port 80 from world and port 22 (ssh) from jump host (${JUMP_HOST_IP})"
aws ec2 create-security-group --group-name wpenv --description "security group for wordpress environment in EC2"
aws ec2 authorize-security-group-ingress --group-name wpenv --protocol tcp --port 22 --cidr $JUMP_HOST_IP/32
aws ec2 authorize-security-group-ingress --group-name wpenv --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 create-key-pair --key-name wpenv-key --query 'KeyMaterial' --output text > wpenv-key.pem
chmod 400 wpenv-key.pem
	print_logs "Done"

	print_logs "Starting WORDPRESS server"
chmod +x ~/wordpress-config.sh
aws ec2 run-instances --image-id ami-1b791862 --security-group-ids $(aws ec2 describe-security-groups | grep wpenv -n3|grep GroupId| cut -d"\"" -f4) --count 1 --instance-type t2.micro --key-name wpenv-key  > wordpress_server.out
chown ubuntu: wordpress_server.out
	print_logs "wait 40 seconds, instance is starting...."
for i in `seq 40`
do
	sleep 1
	echo $((40-$i))
done	
NEW_SERVER=$(grep "PrivateIpAddress" wordpress_server.out |grep -v $(ip a |grep " inet "|grep -v 127|cut -d" " -f 6|cut -d'/' -f1)|cut -d'"' -f4|sort|uniq |grep ".")
NEW_SERVER_PUBLIC_IP=$(aws ec2 describe-instances| grep wpenv -A40 |grep PublicIpAd|cut -d"\"" -f 4)
	print_logs "The private IP for WORDPRESS server is ${NEW_SERVER}"

	print_logs "Start configuring WORDPRESS instance"
scp -i wpenv-key.pem -o StrictHostKeyChecking=no ~/wordpress-config.sh ubuntu@$NEW_SERVER:~/
ssh -i wpenv-key.pem ubuntu@$NEW_SERVER "sudo ~/wordpress-config.sh"
	print_logs "Server ready on port 80. Please, check the Public IP for WORDPRESS instance ${NEW_SERVER_PUBLIC_IP}"

##################################################################
############################The END
##################################################################
