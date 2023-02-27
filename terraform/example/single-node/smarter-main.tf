provider "aws" {
  region = "eu-west-1"
}

locals {
  deployment_name = "smarter-testing"
}

data "aws_vpc" "vpc" {
  # This assumes that there is a default VPC
  default = true
}

resource "aws_security_group" "sg" {
  name   = "allow_smarter"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    description      = "allow_ssh"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
  }

  ingress {
    description      = "allow_http"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
  }

  ingress {
    description      = "allow_https"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
  }

  ingress {
    description      = "allow_k3s_inbound"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    from_port         = 6443
    to_port           = 6443
    protocol          = "tcp"
  }

  ingress {
    description      = "allow_k3s_edge_inbound"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    from_port        = 6444
    to_port          = 6444
    protocol         = "tcp"
  }

  ingress {
    description      = "allow_k3s_https_inbound"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    from_port        = 6446
    to_port          = 6446
    protocol         = "tcp"
  }

  ingress {
    description      = "allow_fluentbit_inbound"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    from_port        = 30224
    to_port          = 30224
    protocol         = "tcp"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_smarter"
  }
}

module "ssh_key_pair" {
  # tflint-ignore: terraform_module_pinned_source
  source                = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=master"
  namespace             = local.deployment_name
  stage                 = "prod"
  name                  = "k3s"
  ssh_public_key_path   = "ssh"
  generate_ssh_key      = "true"
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
}

module "k3s" {
  source = "../../"

  providers = {
    aws = aws
  }

  assign_public_ip   = true
  deployment_name    = "smarter-testing"
  instance_type      = "t3a.medium"
  #ami_id = ami-0333305f9719618c7 (ubuntu 22.04 20230115)
  subnet_id          = "subnet-0a0e6c54239cf12fc"
  keypair_content    = module.ssh_key_pair.public_key
  security_group_ids = [aws_security_group.sg.id]
  kubeconfig_mode    = "644"
  letsencrypt_email  = "xxx@yyy.com"
}

output "k3s_master_public_dns" {
  value = module.k3s.instance.public_dns
  description = "EC2 instance name allocated"
}

output "k3s_edge" {
  value = module.k3s.k3s_edge.result
  description = "System-wide password: grafana admin, k3s-edge ID"
}
