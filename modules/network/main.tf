data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  availability_zones = var.availability_zones != null ? var.availability_zones : data.aws_availability_zones.available.names
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr


  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }

}

#internet gateway 
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }

}

#elastic ip for nat gateway
resource "aws_eip" "nat" {
  count  = var.environment == "prod" ? 2 : 1
  domain = "vpc"

  tags = {
    name        = "${var.environment}-nat-eip-${count.index}"
    Environment = var.environment
  }

}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(local.availability_zones, count.index % length(local.availability_zones))
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Tier        = "web"
  }
}

#private subnets

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(local.availability_zones, count.index % length(local.availability_zones))

  tags = {
    Name = "${element(["app", "database"], floor(count.index / 2))}-private-subnet-${count.index % 2 + 1}"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count         = var.environment == "prod" ? 2 : 1
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name        = "${var.environment}-nat-gw-${count.index + 1}"
    Environment = var.environment
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-public-route"
    Environment = var.environment
  }
}

# Public Route Table Association
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# Private Route Tables
resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index % (var.environment == "prod" ? 2 : 1)].id
  }

  tags = {
    Name        = "${var.environment}-private-route-${count.index + 1}"
    Environment = var.environment
    Tier        = count.index < 2 ? "app" : "database"
  }
}

# Private Route Table Association
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Database Subnet Group
resource "aws_db_subnet_group" "database" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = [aws_subnet.private[2].id, aws_subnet.private[3].id]

  tags = {
    Name        = "${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}
