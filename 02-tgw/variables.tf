variable "vpc1_id"       { type = string }
variable "vpc2_id"       { type = string }
variable "vpc3_id"       { type = string }

variable "subnet1_id"    { type = string }
variable "subnet2_id"    { type = string }
variable "subnet3_id"    { type = string }

variable "rt1_id"        { type = string }
variable "rt2_id"        { type = string }
variable "rt3_id"        { type = string }

# VPC1 public route table — return routes for spoke VPCs added here
variable "public_rt1_id" { type = string }

variable "sg1_id"        { type = string }
variable "sg2_id"        { type = string }
variable "sg3_id"        { type = string }
