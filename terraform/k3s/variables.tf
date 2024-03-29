variable "keypair_path" {
  type        = string
  default     = ""
  description = "The path to the public key to use for the instance."
}

variable "keypair_content" {
  type        = string
  default     = ""
  description = "The raw data to be used for the public key for the instance. If this is used, no value must be specified for 'keypair_path'."
}

variable "deployment_name" {
  type        = string
  default     = "k3s"
  description = "A unique name used to generate other names for resources, such as instance names."
}

variable "iam_role_name" {
  type        = string
  default     = null
  description = "The name of an IAM Role to assign to the instance. If left blank, no role will be assigned."
}

variable "subnet_id" {
  type        = string
  default     = ""
  description = "The ID of a VPC subnet to assign the instance to. If left blank, the instance will be provisioned in the default subnet of the default VPC."
}

variable "security_group_ids" {
  type        = list(string)
  description = "A list of Security Group IDs to assign to the instance."
}

variable "assign_public_ip" {
  type        = bool
  default     = true
  description = "If set to 'true', a public IP address will be assigned to the instance."
}

variable "instance_type" {
  type        = string
  default     = "t3.small"
  description = "The AWS EC2 Instance Type to provision the instance as."
}

variable "manifest_bucket_path" {
  type        = string
  default     = ""
  description = "The AWS S3 bucket name and path that will be used to download manifest files for auto-installation as per [this documentation](https://rancher.com/docs/k3s/latest/en/advanced/). Should be specified as 'bucket name/folder name/'. The IAM Role assigned to the instance must have GetObject access to this bucket."
}

variable "enable_worker_nodes" {
  type        = bool
  description = "If set to 'true', a separate autoscaling group will be created for worker nodes."
  default     = false
}

variable "worker_node_min_count" {
  type        = number
  description = "The minimum number of worker node instances to provision."
  default     = 0
}

variable "worker_node_max_count" {
  type        = number
  description = "The maximum number of worker node instances to provsion."
  default     = 0
}

variable "worker_node_desired_count" {
  type        = number
  description = "The desired number of worker nodes to provision."
  default     = 0
}

variable "kubeconfig_mode" {
  type        = string
  description = "Sets the file mode of the generated KUBECONFIG file on the master k3s instance. Defaults to '600'."
  default     = "600"
}

variable "letsencrypt_email" {
  type        = string
  description = "Email to be used in letsencrypt to generate certificates. No default"
}

variable "ami_id" {
  type        = string
  description = "The AMI ID to use when provisioning the instance. If left at the default null value, the latest Ubuntu server image is used."
  default     = null
}

