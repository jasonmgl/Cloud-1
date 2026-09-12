data "aws_caller_identity" "current" {}

locals {
  ansible_ssh_private_key_file = pathexpand(var.ssh_private_key_path)
  inventory_ansible_path       = coalesce(var.inventory_ansible_path, "${path.module}/../ansible/inventory.ini")
  instance_groups = {
    for group_key, group in var.instance_groups : group_key => {
      name = coalesce(group.name, group_key)
      instances = {
        for instance_key, instance in group.instances : instance_key => {
          name = coalesce(instance.name, "${coalesce(group.name, group_key)}-${instance_key}")
        }
      }
    }
  }
  instances = merge([
    for group_key, group in local.instance_groups : {
      for instance_key, instance in group.instances : "${group_key}.${instance_key}" => {
        group_key    = group_key
        group_name   = group.name
        instance_key = instance_key
        name         = instance.name
      }
    }
  ]...)

  instance_user_data = <<EOF
  #! /bin/bash
  
  sudo apt update -y
  sudo apt install -y python3
  EOF

  security_group_ingress_rules = {
    http = {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
    }
    https = {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      cidr_blocks = ["0.0.0.0/0"]
    }
    ssh = {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      cidr_blocks = [var.ssh_allowed_cidr]
    }
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "instances" {
  for_each = local.instances

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.nb-keypair.key_name
  vpc_security_group_ids = [aws_security_group.instance_groups[each.value.group_key].id]
  user_data              = local.instance_user_data

  tags = {
    Group = each.value.group_name
    Name  = each.value.name
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip" "instances" {
  for_each = aws_instance.instances

  domain   = "vpc"
  instance = each.value.id

  tags = {
    Name = "${local.instances[each.key].name}-eip"
  }
}

resource "aws_security_group" "instance_groups" {
  for_each = local.instance_groups

  name        = "custom-security-group-${each.key}"
  description = "Allow SSH, HTTP, and HTTPS access to the ${each.value.name} EC2 instances"

  dynamic "ingress" {
    for_each = local.security_group_ingress_rules
    iterator = rule

    content {
      description = rule.value.description
      from_port   = rule.value.from_port
      to_port     = rule.value.to_port
      protocol    = "tcp"
      cidr_blocks = rule.value.cidr_blocks
    }
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${each.value.name}-security-group"
  }
}

resource "aws_key_pair" "nb-keypair" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.nb-keypair.public_key_openssh
}

resource "aws_ec2_instance_state" "instances" {
  for_each = aws_instance.instances

  instance_id = each.value.id
  state       = var.instance_power_state
}

resource "tls_private_key" "nb-keypair" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.nb-keypair.private_key_pem
  filename        = local.ansible_ssh_private_key_file
  file_permission = "0600"
}

resource "local_file" "ansible_inventory" {
  filename = local.inventory_ansible_path

  content = join("\n\n", concat(
    [
      "[aws]\n${join("\n", [
        for key, instance in aws_instance.instances :
        "${local.instances[key].name} ansible_host=${aws_eip.instances[key].public_ip} ansible_ssh_private_key_file=${local.ansible_ssh_private_key_file} ansible_ssh_user=${var.ansible_ssh_user}${key == var.dns_target_instance && var.domain_name != "" ? " domain_name=${var.domain_name}" : ""}"
      ])}"
    ],
    [
      for group_key, group in local.instance_groups :
      "[${group_key}]\n${join("\n", [
        for instance_key, instance in group.instances :
        "${instance.name} ansible_host=${aws_eip.instances["${group_key}.${instance_key}"].public_ip} ansible_ssh_private_key_file=${local.ansible_ssh_private_key_file} ansible_ssh_user=${var.ansible_ssh_user}${"${group_key}.${instance_key}" == var.dns_target_instance && var.domain_name != "" ? " domain_name=${var.domain_name}" : ""}"
      ])}"
    ]
  ))
}
