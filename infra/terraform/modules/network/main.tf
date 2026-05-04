locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  private_subnets = merge(
    {
      for az, cidr in var.private_web_subnets :
      "web-${az}" => {
        az   = az
        cidr = cidr
        tier = "web"
      }
    },
    {
      for az, cidr in var.private_app_subnets :
      "app-${az}" => {
        az   = az
        cidr = cidr
        tier = "app"
      }
    },
    {
      for az, cidr in var.private_db_subnets :
      "db-${az}" => {
        az   = az
        cidr = cidr
        tier = "db"
      }
    }
  )
}

# =========================
# VPC
# =========================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-vpc"
    }
  )
}

# =========================
# Public Subnets
# =========================

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"
      Tier = "public"
    }
  )
}

# =========================
# Private Subnets
# =========================

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${each.value.tier}-${each.value.az}"
      Tier = each.value.tier
    }
  )
}

# =========================
# Internet Gateway
# =========================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-igw"
    }
  )
}

# =========================
# Public Route Table
# =========================

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-public-rt"
      Tier = "public"
    }
  )
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# =========================
# NAT Gateway
# =========================

resource "aws_eip" "nat_gw" {
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-nat-eip"
    }
  )
}

resource "aws_nat_gateway" "public_nat_gw" {
  allocation_id = aws_eip.nat_gw.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-nat-gateway"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# =========================
# Private Route Table
# =========================

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-private-rt"
      Tier = "private"
    }
  )
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public_nat_gw.id
}

resource "aws_route_table_association" "private_nat" {
  for_each = {
    for key, subnet in aws_subnet.private :
    key => subnet
    if startswith(key, "web-") || startswith(key, "app-")
  }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt.id
}