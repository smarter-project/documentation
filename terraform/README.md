# Terrform script to install smarter on AWS EC2

It assumes that the enviroment variables AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_SESSION_TOKEN are set correctly so terraform can access AWS.
Set the following variables to correct values:
region (provider "aws): AWS region to allocate an EC2 instance on.
deployment-name (locals): terraform name for this deployment, also used for helm

## Running

Move to the directory example/single-node and update the smarter-main.tf variables: deployment-name and letsencrypt_email to be valid
Run the following command from the directory example/single-node:
```
terraform init
terraform apply
```

## Outputs

Terraform will output the name of EC2 instance allocated and password/ID generated by terraform.

Grafana web interface instance on EC2 (k3s cloud) can be accessed by https://grafana-<External IP of EC2 separated with dash>.nio.io with user admin and password <password/ID>.

A ssh directory will be created locally containing a private/public SSH key that can be used to access the instance using the following command:

```bash
ssh -i ssh/<deployment-name>-prod-k3s.pem ubuntu@<EC2 instance allocated>
```

on the instance access to k3s cloud (running the cloud containers) can be accessed by setting KUBECONFIG to /etc/rancher/k3s/k3s.yaml
The k3s edge, that manages the edge devices and applications running on them, can be accessd by setting KUBECONFIG as $(pwd)/k3s.yaml.<<password/ID>

Helm was used to install charts and can be used to manage them by setting the correct KUBECONFIG

The edge devices can be installed (Raspberry pi4 for example) by running the following script. The command will install k3s agent and connect that to the k3s edge running on the ec2 instanct. The command will install k3s agent and connect that to the k3s edge running on the ec2 instance.
```
wget --no-check-certificate https://<EC2 instance name>:6446/k3s-start.sh.<password/ID> | bash -s -
```
