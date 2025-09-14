# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  intra_subnets   = local.intra_subnets

  # NAT Gateway configuration
  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Internet Gateway
  create_igw = true

  # Public subnet tags for ELB
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${local.name}" = "shared"
  }

  # Private subnet tags for internal ELB
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${local.name}" = "shared"
  }

  # Intra subnet tags
  intra_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "owned"
  }

  tags = local.tags
}