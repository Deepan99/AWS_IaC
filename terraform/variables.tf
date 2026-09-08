variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "ap-south-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-east-1, ap-south-1)."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

variable "key_name" {
  description = "EC2 Key Pair Name for SSH access"
  type        = string
  default     = "hub-vpc-key"
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^t[23]\\.(nano|micro|small|medium|large|xlarge|2xlarge)$", var.instance_type))
    error_message = "Instance type must be a valid t2 or t3 instance (e.g., t3.micro, t2.small)."
  }
}

# Hub Network CIDRs
variable "hub_vpc_cidr" {
  description = "CIDR block for Hub VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.hub_vpc_cidr, 0))
    error_message = "Hub VPC CIDR must be a valid CIDR block."
  }
}

variable "hub_public_subnet_cidr" {
  description = "CIDR block for Hub Public Subnet"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.hub_public_subnet_cidr, 0))
    error_message = "Hub Public Subnet CIDR must be a valid CIDR block."
  }
}

# Spoke 1 Network CIDRs
variable "spoke1_vpc_cidr" {
  description = "CIDR block for Spoke 1 Prod VPC"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.spoke1_vpc_cidr, 0))
    error_message = "Spoke 1 VPC CIDR must be a valid CIDR block."
  }
}

variable "spoke1_private_subnet_cidr" {
  description = "CIDR block for Spoke 1 Private Subnet"
  type        = string
  default     = "10.1.1.0/24"

  validation {
    condition     = can(cidrhost(var.spoke1_private_subnet_cidr, 0))
    error_message = "Spoke 1 Private Subnet CIDR must be a valid CIDR block."
  }
}

# Spoke 2 Network CIDRs
variable "spoke2_vpc_cidr" {
  description = "CIDR block for Spoke 2 Dev VPC"
  type        = string
  default     = "10.2.0.0/16"

  validation {
    condition     = can(cidrhost(var.spoke2_vpc_cidr, 0))
    error_message = "Spoke 2 VPC CIDR must be a valid CIDR block."
  }
}

variable "spoke2_private_subnet_cidr" {
  description = "CIDR block for Spoke 2 Private Subnet"
  type        = string
  default     = "10.2.1.0/24"

  validation {
    condition     = can(cidrhost(var.spoke2_private_subnet_cidr, 0))
    error_message = "Spoke 2 Private Subnet CIDR must be a valid CIDR block."
  }
}

# DNS
variable "private_domain_name" {
  description = "Route 53 Private Hosted Zone Domain"
  type        = string
  default     = "corp.internal"
}
