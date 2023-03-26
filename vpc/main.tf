resource "random_integer" "eks_id" {
  min = 10
  max = 5000
}

locals {
  cluster_name = "eks-${var.environment}-${random_integer.eks_id.result}"
}

resource "aws_vpc" "vpc" {
  cidr_block                     = var.environment == "prod" ? var.aws_vpc_cidr_prod : var.environment == "dev" ? var.aws_vpc_cidr_dev : var.environment == "stage" ? var.aws_vpc_cidr_stage : var.aws_vpc_cidr_dev
  instance_tenancy               = "default"
  enable_dns_hostnames           = "true"
  enable_dns_support             = "true"
  enable_classiclink             = "false"
  enable_classiclink_dns_support = "false"

  tags = {
    Name                                          = "vpc-${var.environment}-eks"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}

resource "aws_eip" "eip" {
  vpc = true
  tags = {
    Name = "${var.environment}-nat-eip"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.environment}-igw"
  }
}


resource "aws_route_table" "route_tables_private" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.environment}-private-route"
  }
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
}

resource "aws_route_table" "route_tables_public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = {
    Name = "${var.environment}-public-route"
  }
}

resource "aws_route_table" "route_tables_db" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.environment}-db-route"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.eip.id
  subnet_id     = element(aws_subnet.app_public.*.id, 1)
  tags = {
    Name = "${var.environment}-nat-gw"
  }
}


resource "aws_subnet" "db_private" {
  count             = var.environment == "prod" ? length(var.aws_cidrs_db_prod) : var.environment == "dev" ? length(var.aws_cidrs_db_dev) : var.environment == "stage" ? length(var.aws_cidrs_db_stage) : length(var.aws_cidrs_db_dev)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.environment == "prod" ? element(var.aws_cidrs_db_prod, count.index) : var.environment == "dev" ? element(var.aws_cidrs_db_dev, count.index) : var.environment == "stage" ? element(var.aws_cidrs_db_stage, count.index) : element(var.aws_cidrs_db_dev, count.index)
  availability_zone = var.environment == "prod" ? element(var.aws_azs_prod, count.index) : var.environment == "prod-dr" ? element(var.aws_azs_prod_dr, count.index) : var.environment == "dev" ? element(var.aws_azs_dev, count.index) : var.environment == "stage" ? element(var.aws_azs_stage, count.index) : element(var.aws_azs_dev, count.index)
  tags = {
    Name = "${var.environment}-db-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "app_private" {
  count             = var.environment == "prod" ? length(var.aws_cidrs_private_prod) : var.environment == "dev" ? length(var.aws_cidrs_private_dev) : var.environment == "stage" ? length(var.aws_cidrs_private_stage) : length(var.aws_cidrs_private_dev)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.environment == "prod" ? element(var.aws_cidrs_private_prod, count.index) : var.environment == "dev" ? element(var.aws_cidrs_private_dev, count.index) : var.environment == "stage" ? element(var.aws_cidrs_private_stage, count.index) : element(var.aws_cidrs_private_dev, count.index)
  availability_zone = var.environment == "prod" ? element(var.aws_azs_prod, count.index) : var.environment == "prod-dr" ? element(var.aws_azs_prod_dr, count.index) : var.environment == "dev" ? element(var.aws_azs_dev, count.index) : var.environment == "stage" ? element(var.aws_azs_stage, count.index) : element(var.aws_azs_dev, count.index)
  tags = {
    Name                                          = "${var.environment}-private-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
    "karpenter.sh/discovery"                      = local.cluster_name
  }
}

resource "aws_subnet" "app_public" {
  count                   = var.environment == "prod" ? length(var.aws_cidrs_public_prod) : var.environment == "dev" ? length(var.aws_cidrs_public_dev) : var.environment == "stage" ? length(var.aws_cidrs_public_stage) : length(var.aws_cidrs_public_dev)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.environment == "prod" ? element(var.aws_cidrs_public_prod, count.index) : var.environment == "dev" ? element(var.aws_cidrs_public_dev, count.index) : var.environment == "stage" ? element(var.aws_cidrs_public_stage, count.index) : element(var.aws_cidrs_public_dev, count.index)
  availability_zone       = var.environment == "prod" ? element(var.aws_azs_prod, count.index) : var.environment == "prod-dr" ? element(var.aws_azs_prod_dr, count.index) : var.environment == "dev" ? element(var.aws_azs_dev, count.index) : var.environment == "stage" ? element(var.aws_azs_stage, count.index) : element(var.aws_azs_dev, count.index)
  map_public_ip_on_launch = "true"
  tags = {
    Name                                          = "${var.environment}-public-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.environment == "prod" ? length(var.aws_cidrs_public_prod) : var.environment == "dev" ? length(var.aws_cidrs_public_dev) : var.environment == "stage" ? length(var.aws_cidrs_public_stage) : length(var.aws_cidrs_public_dev)
  subnet_id      = element(aws_subnet.app_public.*.id, count.index)
  route_table_id = aws_route_table.route_tables_public.id
}

resource "aws_route_table_association" "private" {
  count          = var.environment == "prod" ? length(var.aws_cidrs_private_prod) : var.environment == "dev" ? length(var.aws_cidrs_private_dev) : var.environment == "stage" ? length(var.aws_cidrs_private_stage) : length(var.aws_cidrs_private_dev)
  subnet_id      = element(aws_subnet.app_private.*.id, count.index)
  route_table_id = aws_route_table.route_tables_private.id
}

resource "aws_route_table_association" "db" {
  count          = var.environment == "prod" ? length(var.aws_cidrs_db_prod) : var.environment == "dev" ? length(var.aws_cidrs_db_dev) : var.environment == "stage" ? length(var.aws_cidrs_db_stage) : length(var.aws_cidrs_db_dev)
  subnet_id      = element(aws_subnet.db_private.*.id, count.index)
  route_table_id = aws_route_table.route_tables_db.id
}

resource "aws_flow_log" "example" {
  log_destination      = aws_s3_bucket.aws_s3_bucket.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.vpc.id
}

resource "random_integer" "id" {
  min = 100000
  max = 500000
}

resource "aws_s3_bucket" "aws_s3_bucket" {
  bucket        = "${var.environment}-vpc-flow-logs-${random_integer.id.result}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "vpc_flow" {
  bucket                  = aws_s3_bucket.aws_s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
