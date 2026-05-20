output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "api_subnets" {
  value = aws_subnet.api[*].id
}

output "db_subnets" {
  value = aws_subnet.db[*].id
}
