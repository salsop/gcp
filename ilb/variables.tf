variable "mgmt_cidr" {
  type = string
}
variable "data_cidr" {
  type = string
}

variable "name" {
  description = "Name/Prefix of the deployment"
  type = string
}

variable "vpc_count" {
  description = "Number of data vpcs to deploy"
  type = number
}
variable "fw_count" {
  description = "Number of fws to deploy"
  type = number
}

variable "machine_type" {
  type = string
}

variable "bootstrap_options" {
  type = map
}

variable "ssh_key" {
  type = string
}

variable "mgmt_ips" {
  description = "List of IPs allowed for external access"
  type = list(map(string))
}
