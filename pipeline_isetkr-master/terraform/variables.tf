variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.large"
}

variable "key_name" {
  description = "Nom de la Key Pair AWS Academy (vockey)"
  type        = string
  default     = "vockey"
}
