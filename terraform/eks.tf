# Alternative EKS configuration for AWS Academy - Minimal approach
# Use this if the main eks.tf still has issues

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"  # Use older version for better compatibility

  cluster_name    = local.name
  cluster_version = "1.27"  # Slightly older but more stable version

  # Cluster endpoint configuration
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # VPC Configuration
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Cluster addons - minimal set
  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  # Managed node groups
  eks_managed_node_groups = {
    main = {
      name = "inescloud-main-nodes"

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"  # Use ON_DEMAND instead of SPOT for stability

      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Use default AMI
      ami_type = "AL2_x86_64"

      # Disk configuration
      disk_size = 30

      labels = {
        Environment = "dev"
        NodeGroup   = "main"
      }

      tags = local.tags
    }
  }

  # Node security group rules - allow basic communication
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }

    egress_all = {
      description = "Node all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = local.tags
}