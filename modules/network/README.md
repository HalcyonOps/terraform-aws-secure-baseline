# network

A VPC with three subnet tiers and a **secure-by-default** posture.

The minimal call produces a network where the safe choices are already made:

- **Three tiers.** `public` (internet-routed), `private` (outbound via NAT,
  no inbound from the internet), and `intra` — fully isolated, with no route
  off the VPC at all. Put databases and internal-only workloads in `intra`.
- **Flow logs on.** Enabled by default to a CloudWatch log group with its own
  scoped IAM role — a CIS AWS Foundations §4 control.
- **Default security group locked.** Declared with no ingress or egress rules,
  so nothing inherits open access from it (CIS §5.4).
- **No accidental public IPs.** `map_public_ip_on_launch` is off — instances
  get addresses from an explicit EIP or load balancer, not by surprise.

Cost-conscious where it does not cost security: `single_nat_gateway` is on by
default (one shared NAT). Set it false for AZ-resilient egress.

## Usage

```hcl
module "network" {
  source = "github.com/R055LE/terraform-aws-secure-baseline//modules/network?ref=v0.2.0"

  name               = "platform"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  intra_subnet_cidrs   = ["10.0.20.0/24", "10.0.21.0/24"]
}
```

See [`examples/network`](../../examples/network) for a runnable example.

## Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.9.0 |
| aws | >= 5.40, < 7.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.flow_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_default_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.flow_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.flow_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_internet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.intra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.intra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.intra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_iam_policy_document.flow_log_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.flow_log_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| availability\_zones | Availability zones for the subnets. Subnet CIDRs are placed into these zones in list order. | `list(string)` | n/a | yes |
| cidr\_block | IPv4 CIDR block for the VPC. | `string` | n/a | yes |
| name | Name prefix applied to the VPC and all child resources. | `string` | n/a | yes |
| enable\_dns\_hostnames | Assign DNS hostnames to instances in the VPC. | `bool` | `true` | no |
| enable\_dns\_support | Enable DNS resolution within the VPC. | `bool` | `true` | no |
| enable\_flow\_log | Send VPC flow logs to CloudWatch Logs. On by default — flow logs are a CIS AWS Foundations control (§4). | `bool` | `true` | no |
| enable\_nat\_gateway | Provision NAT gateway(s) so private subnets have outbound internet access. | `bool` | `true` | no |
| flow\_log\_kms\_key\_arn | ARN of a KMS key to encrypt the flow log group. When null, CloudWatch Logs uses AWS-managed encryption. | `string` | `null` | no |
| flow\_log\_retention\_days | Retention period, in days, for the flow log CloudWatch log group. | `number` | `90` | no |
| flow\_log\_traffic\_type | Which traffic the flow log captures: ALL, ACCEPT, or REJECT. | `string` | `"ALL"` | no |
| intra\_subnet\_cidrs | CIDR blocks for intra subnets — fully isolated, with no route off the VPC. Intended for databases and internal-only workloads. | `list(string)` | `[]` | no |
| map\_public\_ip\_on\_launch | Auto-assign a public IP to instances launched in public subnets. Off by default — attach an explicit EIP or load balancer instead. | `bool` | `false` | no |
| private\_subnet\_cidrs | CIDR blocks for private subnets — outbound via NAT, no inbound route from the internet. | `list(string)` | `[]` | no |
| public\_subnet\_cidrs | CIDR blocks for public subnets — routed to an internet gateway. One subnet per entry. | `list(string)` | `[]` | no |
| single\_nat\_gateway | Use one shared NAT gateway instead of one per availability zone. On by default to keep cost down; set false for AZ-resilient egress, which expects public and private subnet lists of equal length. | `bool` | `true` | no |
| tags | Tags applied to all resources created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| default\_security\_group\_id | ID of the VPC default security group, locked with no rules. |
| flow\_log\_id | ID of the VPC flow log, or null when flow logs are disabled. |
| flow\_log\_log\_group\_name | Name of the flow log CloudWatch log group, or null when flow logs are disabled. |
| internet\_gateway\_id | ID of the internet gateway, or null when no public subnets exist. |
| intra\_subnet\_ids | IDs of the intra (isolated) subnets. |
| nat\_gateway\_ids | IDs of the NAT gateways. |
| private\_subnet\_ids | IDs of the private subnets. |
| public\_subnet\_ids | IDs of the public subnets. |
| vpc\_arn | ARN of the VPC. |
| vpc\_cidr\_block | CIDR block of the VPC. |
| vpc\_id | ID of the VPC. |
<!-- END_TF_DOCS -->
