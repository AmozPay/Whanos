#!/bin/sh

set -ae
source ./.env
set +a

# export TF_LOG=DEBUG

if [[ "$#" -lt "1" ]];
then
	echo "Usage: deployment.sh [create|delete] OPTIONS"
	echo "Options:"
	echo "		--skip-terraform, -s		skip resource creation"
	exit 1
fi

if [[ "$DIGITAL_OCEAN_TOKEN" == "" ]];
then
	echo "value DIGITAL_OCEAN_TOKEN missing in .env"
	exit 1
fi

if [[ "$PROJECT_NAME" == "" ]];
then
	echo "value PROJECT_NAME missing in .env"
	exit 1
fi

if [[ "$DIGITAL_OCEAN_SSH_KEY_ID" == "" ]];
then
	echo "value DIGITAL_OCEAN_SSH_KEY_ID missing in .env"
	exit 1
fi

if [[ "$DOMAIN_NAME" == "" ]];
then
	echo "value DOMAIN_NAME missing in .env"
	exit 1
fi

if [[ "$CERTIFICATE_EMAIL" == "" ]];
then
	echo "value CERTIFICATE_EMAIL missing in .env"
	exit 1
fi

TERRAFORM_VARS="-var ssh_key_id=$DIGITAL_OCEAN_SSH_KEY_ID -var digitalocean_token=$DIGITAL_OCEAN_TOKEN -var domain=$DOMAIN_NAME -var project_name=$PROJECT_NAME"

if [[ $SUBDOMAIN != "" ]];
then
	TERRAFORM_VARS="$TERRAFORM_VARS -var subdomain=$SUBDOMAIN"
fi

if [[ $DIGITAL_OCEAN_REGION != "" ]];
then
	TERRAFORM_VARS="$TERRAFORM_VARS -var region=$DIGITAL_OCEAN_REGION"
fi

if [[ $DROPLET_SIZE != "" ]];
then
	TERRAFORM_VARS="$TERRAFORM_VARS -var size=$DROPLET_SIZE"
fi

cd terraform
terraform init

case $1 in
	create)

		if [[ "$2" != "--skip-terraform" &&  "$2" != "-s" ]];
		then
			terraform apply -auto-approve $TERRAFORM_VARS
			echo "Waiting for ssh server to be ready"
			sleep 30
		else
			echo "skipping terraform"
		fi

		# K8_IP="$(terraform output -raw k8_ipv4)"
		JENKINS_IP="$(terraform output -raw jenkins_ipv4)"
		REGISTRY_IP="$(terraform output -raw registry_ipv4)"


		cd ../ansible
		echo -ne "[kubernetes]\n$K8_IP	ansible_ssh_private_key_file=$HOME/.ssh/id_rsa ansible_user=root\n" > hosts.txt
		echo -ne "[jenkins]\n$JENKINS_IP	ansible_ssh_private_key_file=$HOME/.ssh/id_rsa ansible_user=root ansible_become_password=$BECOME_PASS\n" >> hosts.txt
		echo -ne "[registry]\n$REGISTRY_IP	ansible_ssh_private_key_file=$HOME/.ssh/id_rsa ansible_user=root  ansible_become_password=$BECOME_PASS\n" >> hosts.txt

		echo "registry_user: $REGISTRY_USER" > vars.yml
		echo "registry_passwd: $REGISTRY_PASSWD" >> vars.yml
		echo "domain_name: $DOMAIN_NAME" >> vars.yml
		echo "jenkins_admin_user: $JENKINS_ADMIN_USER" >> vars.yml
		echo "jenkins_admin_passwd: $JENKINS_ADMIN_PASSWD" >> vars.yml
		ansible-galaxy install -r requirements.yml
		export ANSIBLE_HOST_KEY_CHECKING=False
		ansible-playbook playbook.yml -i ./hosts.txt
	;;

	delete)
		terraform destroy -auto-approve $TERRAFORM_VARS

	;;
	*)
		echo "Invalid argument $1"
		exit 1
esac