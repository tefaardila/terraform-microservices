variable "tag_project" {
  description = "Value of project key tag"
  type        = string
  default     = "sthefania.ardilab-ramp-up-devops"
}

variable "tag_responsible" {
  description = "Value of responsible key tag"
  type        = string
  default     = "sthefania.ardilab"
}
variable "instance_type" {
  description = "Instance type in aws"
  type        = string
  default     = "t2.micro"
}
variable "ami" {
  description = "Ami in aws"
  type        = string
  default     = "ami-0729e439b6769d6ab"
}
variable "key_pem" {
  description = "Key pem name"
  type        = string
  default     = "public-proyect"
}
variable "connection_ssh" {
  description = "ssh type of connection"
  type        = string
  default     = "ssh"
}
variable "connection_user" {
  description = "ssh type of connection"
  type        = string
  default     = "ubuntu"
}