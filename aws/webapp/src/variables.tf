variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2
}

variable "environment" {
  type    = string
  default = "dev01"
}

variable "web_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "api_port" {
  type    = number
  default = 8080
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "web_sg_name" {
  type    = string
  default = "web-sg"
}

variable "api_sg_name" {
  type    = string
  default = "api-sg"
}

variable "db_sg_name" {
  type    = string
  default = "db-sg"
}
