variable "vpc_id" {
  type = string
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
