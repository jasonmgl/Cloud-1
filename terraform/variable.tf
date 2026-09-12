variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "instance_groups" {
  description = "EC2 instance groups to create. Each group gets its own security group and contains its own instances."
  type = map(object({
    name = optional(string)
    instances = map(object({
      name = optional(string)
    }))
  }))
  default = {
    web = {
      name = "web"
      instances = {
        "1" = {
          name = "web-1"
        }
      }
    }
  }

  validation {
    condition = length(var.instance_groups) > 0 && alltrue([
      for _, group in var.instance_groups : length(group.instances) > 0
    ])
    error_message = "You must define at least one group, and each group must contain at least one instance."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_power_state" {
  description = "Desired EC2 instance power state managed by Terraform. Use running to start instances, or stopped to stop them."
  type        = string
  default     = "running"

  validation {
    condition     = contains(["running", "stopped"], var.instance_power_state)
    error_message = "instance_power_state must be either running or stopped."
  }
}

variable "key_pair_name" {
  description = "Name of the AWS EC2 key pair created by Terraform"
  type        = string
  default     = "default-key"
}

variable "ssh_private_key_path" {
  description = "Local path where Terraform writes the generated SSH private key"
  type        = string
  default     = "~/.aws/default"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to connect over SSH, for example your public IP with /32"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ansible_ssh_user" {
  description = "SSH user used by Ansible to connect to the instance"
  type        = string
  default     = "ubuntu"
}

variable "inventory_ansible_path" {
  description = "Path for inventory.ini needed by Ansible to connect to instances from SSH"
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Domain name to point at the instance via Cloudflare DNS. Empty to skip DNS and use the bare IP. Can be a subdomain of cloudflare_zone_name."
  type        = string
  default     = ""
}

variable "cloudflare_zone_name" {
  description = "Root domain registered as a Cloudflare zone (e.g. \"example.com\"), used to look up the zone domain_name's DNS record goes into. Required when domain_name is set."
  type        = string
  default     = ""
}

variable "dns_target_instance" {
  description = "Which instance (group.instance key, e.g. \"web.1\") domain_name points at"
  type        = string
  default     = "web.1"
}
