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

if [[ "$DIGITAL_OCEAN_KUBECTL_TOKEN" == "" ]];
then
	echo "value DIGITAL_OCEAN_KUBECTL_TOKEN missing in .env"
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
		else
			echo "skipping terraform"
		fi

		seconds_to_wait=5

		K8_ID="$(terraform output -raw k8_id)"
		JENKINS_IP="$(terraform output -raw jenkins_ipv4)"
		REGISTRY_IP="$(terraform output -raw registry_ipv4)"
		echo "Waiting for ssh connections to be ready"
		for i in {1..20}
		do
			echo "Attempt n. $i of 20"
			if ( ! (ssh -o StrictHostKeyChecking=no "root@$JENKINS_IP" "true") || ! ( ssh -o StrictHostKeyChecking=no "root@$REGISTRY_IP" "true"));
			then
				echo "waiting $seconds_to_wait more seconds"
				sleep $seconds_to_wait
			else
				echo "Servers ready to accept connections"
				break
			fi
		done


		cd ../ansible
		echo -ne "[jenkins]\n$JENKINS_IP	ansible_ssh_private_key_file=$HOME/.ssh/id_rsa ansible_user=root ansible_become_password=$BECOME_PASS\n" > hosts.txt
		echo -ne "[registry]\n$REGISTRY_IP	ansible_ssh_private_key_file=$HOME/.ssh/id_rsa ansible_user=root  ansible_become_password=$BECOME_PASS\n" >> hosts.txt

		echo "registry_user: $REGISTRY_USER" > vars.yml
		echo "registry_passwd: $REGISTRY_PASSWD" >> vars.yml
		echo "certificate_email: $CERTIFICATE_EMAIL" >> vars.yml
		echo "domain_name: $DOMAIN_NAME" >> vars.yml
		echo "jenkins_admin_user: $JENKINS_ADMIN_USER" >> vars.yml
		echo "jenkins_admin_passwd: $JENKINS_ADMIN_PASSWD" >> vars.yml
		echo "digitalocean_token: $DIGITAL_OCEAN_KUBECTL_TOKEN" >> vars.yml
		echo "k8_id: $K8_ID" >> vars.yml
		ansible-galaxy install -r requirements.yml
		ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook playbook.yml -i ./hosts.txt
	;;

	delete)
		terraform destroy -auto-approve $TERRAFORM_VARS

	;;
	*)
		echo "Invalid argument $1"
		exit 1
esac