# Whanos

## Wha- what is this name?

It's MCU's Thanos as a Whale. I guess because Whales and Containers are intimally connected, and that Thanos can do lot's of stuff with a single snap.

(Don't ask me, I did not come up whis this somewhat meaningfull though quite particular name. If you like it, you can try to join Epitech's pedagogical team, you'd probably have a blast)

## What it can do

This project can automatically build and deploy containers on a kubernetes cluster from a git repository.

Supported languages / detection trigger file:
 - javascript / `package.json`
 - C / `Makefile`
 - Java / `pom.xml`
 - befunge / `main.bf`
 - python / `requirements.txt`


If `/whanos.yml` is found, the containers will be deployed on the cluster


## Accessing deployed Apps

Deployed apps naming follows this pattern: "GITHUB_USER-REPO-BRANCH_NAME"

The app will be available at http://K8_CLUSTER_IP/APP_NAME

To get the accessible IP, ssh as root into jenkins instance and run the following command:

`sudo -u jenkins kubectl --kubeconfig=/var/lib/jenkins/.kube/config --namespace ingress-nginx get services`

TLS is not available in this version

Ports defined in whanos.yml will be forwarded respectively to the cluster's port.

e.g: if whanos.yml defines a port 80, then app will be accessible at  http://K8_CLUSTER_IP:80/APP_NAME

Default standalone apps will have container port 80 exposed


## Deployment

### I have no infrastructure

Required:
- Terraform
- A digital ocean account
- A domain name that belongs to you and is managed by digital ocean
- Python
- Ansible

Steps:
 - Copy `.env.example` to `.env` and fill it with your info
 - adapt or delete the cloud seting in `terraform/provider.tf` to match your cloud or to save the infrastructure state locally
 - install python requirements with `pip3 install -r requirements.txt`
 - run `./deployment.sh create`

This will create 3 resources
 - A docker container registry at `registry.DOMAIN_NAME`
 - A jenkins instance at `jenkins.DOMAIN_NAME`
 - A kubernetes cluster


### I have infrastructure

Required:
 - A fedora server at `registry.DOMAIN_NAME`
 - A fedora server at `jenkins.DOMAIN_NAME`
 - A kubernetes cluster
 - Python
 - Ansible

Steps:
 - Copy `ansible/vars.example.yml` to `ansible/vars.yml` and fill it with your info
 - install python requirements with `pip3 install -r requirements.txt`
 - install ansible requirements with `ansible-galaxy install -r ansible requirements.yml`
 - setup your ansible hosts file
 - run `cd ansible && ansible-playbook playbook.yml`


