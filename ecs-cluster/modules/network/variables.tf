variable "region" {
  type = string
}

variable "cidr_block" {
  type        = string
  description = "VPC CIDR Block"
}

variable "cidr_block_newbits" {
  type = number
}

variable "network_name" {
  type = string
}

variable "subnet_1_zone" {
  type = string
}

variable "subnet_2_zone" {
  type = string
}

variable "environment_tag" {
  type = string
}
