data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  default_tags = {
    Environment = var.environment
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.default_tags, {
    Name = "three-tier-vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.default_tags, {
    Name = "main-igw"
  })
}

resource "aws_subnet" "public" {
  count = var.az_count

  vpc_id                  = aws_vpc.main.id
  availability_zone       = local.azs[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true

  tags = merge(local.default_tags, {
    Name = "public-${local.azs[count.index]}"
    Tier = "web"
  })
}

resource "aws_subnet" "api" {
  count = var.az_count

  vpc_id            = aws_vpc.main.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)

  tags = merge(local.default_tags, {
    Name = "api-${local.azs[count.index]}"
    Tier = "api"
  })
}

resource "aws_subnet" "db" {
  count = var.az_count

  vpc_id            = aws_vpc.main.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)

  tags = merge(local.default_tags, {
    Name = "db-${local.azs[count.index]}"
    Tier = "database"
  })
}

resource "aws_eip" "nat" {
  count = var.az_count

  domain = "vpc"

  tags = merge(local.default_tags, {
    Name = "nat-eip-${count.index}"
  })
}

resource "aws_nat_gateway" "nat" {
  count = var.az_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.igw]

  tags = merge(local.default_tags, {
    Name = "nat-${local.azs[count.index]}"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.default_tags, {
    Name = "public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = var.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "api" {
  count = var.az_count

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = merge(local.default_tags, {
    Name = "api-rt-${local.azs[count.index]}"
  })
}

resource "aws_route_table_association" "api" {
  count = var.az_count

  subnet_id      = aws_subnet.api[count.index].id
  route_table_id = aws_route_table.api[count.index].id
}

resource "aws_route_table" "db" {
  count = var.az_count

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = merge(local.default_tags, {
    Name = "db-rt-${local.azs[count.index]}"
  })
}

resource "aws_route_table_association" "db" {
  count = var.az_count

  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db[count.index].id
}

resource "aws_db_subnet_group" "main" {
  name = "main-db-subnet-group"

  subnet_ids = aws_subnet.db[*].id

  tags = merge(local.default_tags, {
    Name = "main-db-subnet-group"
  })
}
