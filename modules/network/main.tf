# network — a VPC with three subnet tiers: public (internet-routed), private
# (NAT egress only), and intra (no route off the VPC at all). Flow logs are on
# and the default security group is locked shut by default.

locals {
  # NAT gateways live in public subnets, so they require at least one public
  # subnet and at least one private subnet to serve. One when single, otherwise
  # one per public subnet (availability zone).
  nat_gateway_count = (
    var.enable_nat_gateway
    && length(var.private_subnet_cidrs) > 0
    && length(var.public_subnet_cidrs) > 0
    ? (var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs))
    : 0
  )
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, { Name = var.name })
}

# Lock the default security group: declaring it with no ingress or egress
# blocks revokes every rule. Workloads get their own security groups; nothing
# rides on the default one. (CIS AWS Foundations §5.4)
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-default-locked" })
}

# --- Public tier -----------------------------------------------------------

resource "aws_internet_gateway" "this" {
  count = length(var.public_subnet_cidrs) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = var.name })
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(var.tags, {
    Name = "${var.name}-public-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_route_table" "public" {
  count = length(var.public_subnet_cidrs) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-public" })
}

resource "aws_route" "public_internet" {
  count = length(var.public_subnet_cidrs) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# --- NAT -------------------------------------------------------------------

resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name}-nat-${count.index + 1}" })
}

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, { Name = "${var.name}-nat-${count.index + 1}" })

  depends_on = [aws_internet_gateway.this]
}

# --- Private tier ----------------------------------------------------------

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zones, count.index)

  tags = merge(var.tags, {
    Name = "${var.name}-private-${count.index + 1}"
    Tier = "private"
  })
}

resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-private-${count.index + 1}" })
}

# Default route via NAT. When no NAT is provisioned the private route table
# carries only the local route, leaving the tier without outbound access.
resource "aws_route" "private_nat" {
  count = local.nat_gateway_count > 0 ? length(var.private_subnet_cidrs) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# --- Intra tier (fully isolated — no route off the VPC) --------------------

resource "aws_subnet" "intra" {
  count = length(var.intra_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.intra_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zones, count.index)

  tags = merge(var.tags, {
    Name = "${var.name}-intra-${count.index + 1}"
    Tier = "intra"
  })
}

# One shared route table with no routes added — only the implicit local route
# exists, so intra subnets can reach the VPC and nothing beyond it.
resource "aws_route_table" "intra" {
  count = length(var.intra_subnet_cidrs) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-intra" })
}

resource "aws_route_table_association" "intra" {
  count = length(var.intra_subnet_cidrs)

  subnet_id      = aws_subnet.intra[count.index].id
  route_table_id = aws_route_table.intra[0].id
}

# --- Flow logs -------------------------------------------------------------

resource "aws_cloudwatch_log_group" "flow_log" {
  count = var.enable_flow_log ? 1 : 0

  name              = "/aws/vpc-flow-log/${var.name}"
  retention_in_days = var.flow_log_retention_days
  kms_key_id        = var.flow_log_kms_key_arn

  tags = var.tags
}

data "aws_iam_policy_document" "flow_log_assume" {
  count = var.enable_flow_log ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "flow_log_permissions" {
  count = var.enable_flow_log ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["${aws_cloudwatch_log_group.flow_log[0].arn}:*"]
  }
}

resource "aws_iam_role" "flow_log" {
  count = var.enable_flow_log ? 1 : 0

  name               = "${var.name}-vpc-flow-log"
  assume_role_policy = data.aws_iam_policy_document.flow_log_assume[0].json

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_log" {
  count = var.enable_flow_log ? 1 : 0

  name   = "${var.name}-vpc-flow-log"
  role   = aws_iam_role.flow_log[0].id
  policy = data.aws_iam_policy_document.flow_log_permissions[0].json
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_log ? 1 : 0

  vpc_id               = aws_vpc.this.id
  traffic_type         = var.flow_log_traffic_type
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow_log[0].arn
  iam_role_arn         = aws_iam_role.flow_log[0].arn

  tags = var.tags
}
