terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

resource "random_string" "agent_token" {
  length  = 24
  special = false
}

resource "random_string" "k3s_edge_id" {
  length  = 24
  special = false
}

resource "aws_iam_instance_profile" "instance_profile" {
  name  = "${var.deployment_name}-InstanceProfile"
  role  = var.iam_role_name
  count = var.iam_role_name == null ? 0 : 1
}

data "cloudinit_config" "userData" {
  part {
    content      = <<EOF
#cloud-config
---
hostname: "${var.deployment_name}"
EOF
    content_type = "text/cloud-config"
  }

  part {
    content      = <<EOF
#!/bin/bash
echo "----- Installing k3s"
echo K3S_KUBECONFIG_MODE=${var.kubeconfig_mode} K3S_TOKEN=${random_string.agent_token.result} email=${var.letsencrypt_email} > /tmp/variables
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE=${var.kubeconfig_mode} K3S_TOKEN=${random_string.agent_token.result} sh - 
echo "----- updating ubuntu"
apt-get update -y && apt-get upgrade -y && apt-get install awscli git -y
echo "----- Adding helm"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/ubuntu/.profile
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/ubuntu/.bashrc
export ADVERTISE_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
export PUBLIC_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/public-hostname | cut -d '.' -f 1 | sed 's/^ec2-//')
export LOCAL_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
echo "----- Wating for k3s to start"
until [ -f /etc/rancher/k3s/k3s.yaml ]
do
     sleep 5
done
echo "----- Adding smarter-cloud to k3s"
sudo su - ubuntu bash -c "helm repo add smarter https://smarter-project.github.io/documentation;helm install my-smartercloud smarter/smarter-cloud --set email=${var.letsencrypt_email} --set host=grafana-$PUBLIC_HOSTNAME --set domain=nip.io --set prometheus.grafana.adminPassword=${random_string.k3s_edge_id.result} --wait"
echo "----- Adding smarter-edge to k3s"
sudo su - ubuntu bash -c "helm install my-smartercloud-edge smarter/smarter-k3s-edge --set configuration.externalHostIP=$ADVERTISE_IP --set configuration.hostIP=$LOCAL_IP --set configuration.port=6444 --set configuration.portHTTP=80 --set configuration.id='${random_string.k3s_edge_id.result}' --set configuration.smarter_demo_labels=true --set configuration.host=k3s-$PUBLIC_HOSTNAME --set configuration.domain=nip.io --set configuration.traefik=true --wait"
echo "----- Waiting for k3s.yaml from k3s-edge"
until [ -f /home/ubuntu/k3s.yaml.${random_string.k3s_edge_id.result} ]
do
     sudo su - ubuntu bash -c "wget --no-check-certificate https://k3s-$PUBLIC_HOSTNAME.nip.io:443/k3s.yaml.${random_string.k3s_edge_id.result}"
     sleep 5
done
echo "----- Adding smarter-edge to k3s-edge"
sudo su - ubuntu bash -c "export KUBECONFIG=/home/ubuntu/k3s.yaml.${random_string.k3s_edge_id.result};helm install --create-namespace --namespace smarter my-smartercloud-edge smarter/smarter-edge --wait;helm install --create-namespace --namespace smarter --set global.domain=$(curl http://169.254.169.254/latest/meta-data/public-hostname | cut -d '.' -f 2-) --set smarter-fluent-bit.fluentd.host=$(curl http://169.254.169.254/latest/meta-data/public-hostname | cut -d '.' -f 1) my-smartercloud-demo smarter/smarter-demo --wait"
echo "----- Finished installing"
EOF
    content_type = "text/x-shellscript"
  }

  part {
    content      = var.manifest_bucket_path == "" ? "" : <<EOF
#!/bin/bash
aws s3 sync s3://${var.manifest_bucket_path} /var/lib/rancher/k3s/server/manifests/
EOF
    content_type = "text/x-shellscript"
  }

#  part {
#    content      = <<EOF
##!/bin/bash
#apt-get update && \
#apt-get install ec2-instance-connect -y
#EOF
#    content_type = "text/x-shellscript"
#  }
}

resource "aws_key_pair" "k3s_keypair" {
  key_name   = var.deployment_name
  public_key = var.keypair_content
  count      = 1
}

resource "aws_instance" "k3s_instance" {
  ami                         = var.ami_id == null ? data.aws_ami.ubuntu.id : var.ami_id
  associate_public_ip_address = var.assign_public_ip
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.k3s_keypair[0].key_name
  iam_instance_profile        = var.iam_role_name == null ? null : aws_iam_instance_profile.instance_profile[0].name
  subnet_id                   = var.subnet_id == "" ? "" : var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  user_data                   = data.cloudinit_config.userData.rendered
  tags = {
      Name = "${var.deployment_name}-k3s"
  }
}

output "instance" {
  value = aws_instance.k3s_instance
}

output "k3s_edge" {
  value = random_string.k3s_edge_id
}
