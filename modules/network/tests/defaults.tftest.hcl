# Verifies the secure-by-default posture of the network module.
# Runs against a mocked AWS provider — no credentials, no real API calls.
# Invoke with: terraform -chdir=modules/network test

mock_provider "aws" {
  # aws_iam_policy_document.json is computed; the mock would otherwise return a
  # non-JSON placeholder, and aws_iam_role validates assume_role_policy as JSON
  # at plan time. Supply a valid (empty) policy so that validation passes.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = jsonencode({ Version = "2012-10-17", Statement = [] })
    }
  }
}

# A three-tier VPC built from the minimal required inputs.
run "secure_defaults" {
  command = plan

  variables {
    name                 = "example"
    cidr_block           = "10.0.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
    private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
    intra_subnet_cidrs   = ["10.0.20.0/24", "10.0.21.0/24"]
  }

  assert {
    condition     = aws_vpc.this.enable_dns_support == true && aws_vpc.this.enable_dns_hostnames == true
    error_message = "DNS support and hostnames must be enabled by default."
  }

  assert {
    condition     = length(aws_flow_log.this) == 1
    error_message = "VPC flow logs must be enabled by default."
  }

  assert {
    condition     = alltrue([for s in aws_subnet.public : s.map_public_ip_on_launch == false])
    error_message = "Public subnets must not auto-assign public IPs by default."
  }

  assert {
    condition     = aws_route.public_internet[0].destination_cidr_block == "0.0.0.0/0"
    error_message = "Public subnets must have a default route to the internet gateway."
  }

  # single_nat_gateway defaults true — one shared NAT for both private subnets.
  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "single_nat_gateway is on by default — expected exactly one NAT gateway."
  }

  # The intra tier has its own route table and never receives an aws_route,
  # so it carries only the implicit local route.
  assert {
    condition     = length(aws_route_table.intra) == 1
    error_message = "Intra subnets must share one dedicated, route-free table."
  }
}

# With single_nat_gateway off, each AZ gets its own NAT gateway.
run "ha_nat_per_az" {
  command = plan

  variables {
    name                 = "example"
    cidr_block           = "10.0.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
    private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
    single_nat_gateway   = false
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 2
    error_message = "With single_nat_gateway = false, expected one NAT gateway per AZ."
  }
}

# No public subnets means no internet gateway and no NAT can be placed.
run "no_public_subnets" {
  command = plan

  variables {
    name                 = "example"
    cidr_block           = "10.0.0.0/16"
    availability_zones   = ["us-east-1a"]
    private_subnet_cidrs = ["10.0.10.0/24"]
  }

  assert {
    condition     = length(aws_internet_gateway.this) == 0 && length(aws_nat_gateway.this) == 0
    error_message = "Without public subnets there must be no internet or NAT gateway."
  }
}

# Variable validation rejects bad input before any provider call.
run "invalid_cidr_rejected" {
  command = plan

  variables {
    name               = "example"
    cidr_block         = "not-a-cidr"
    availability_zones = ["us-east-1a"]
  }

  expect_failures = [var.cidr_block]
}

run "invalid_flow_log_traffic_type_rejected" {
  command = plan

  variables {
    name                  = "example"
    cidr_block            = "10.0.0.0/16"
    availability_zones    = ["us-east-1a"]
    flow_log_traffic_type = "EVERYTHING"
  }

  expect_failures = [var.flow_log_traffic_type]
}
