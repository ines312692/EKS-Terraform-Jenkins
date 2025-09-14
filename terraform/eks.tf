# EKS Module - AWS Academy Labs Compatible Version
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = "1.28"

  # Cluster endpoint configuration
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # VPC Configuration
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # Use existing LabRole for cluster service role
  cluster_service_role_arn = data.aws_iam_role.lab_role.arn

  # Cluster addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # EKS Managed Node Group defaults
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["m5.large"]

    # Use LabRole for node groups
    iam_role_arn = data.aws_iam_role.lab_role.arn

    # Security
    attach_cluster_primary_security_group = true

    # Disk configuration
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 30
          volume_type          = "gp3"
          iops                 = 3000
          throughput           = 150
          encrypted            = true
          delete_on_termination = true
        }
      }
    }
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    inescloud-cluster-wg = {
      name = "inescloud-worker-group"

      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"

      # Use LabRole for this node group
      iam_role_arn = data.aws_iam_role.lab_role.arn

      # Scaling configuration
      update_config = {
        max_unavailable_percentage = 50
      }

      # Taints and labels
      labels = {
        Environment = "dev"
        NodeGroup   = "inescloud-worker-group"
      }

      taints = []

      tags = merge(local.tags, {
        ExtraTag = "helloworld"
        NodeGroup = "inescloud-worker-group"
      })
    }
  }

  # Disable cluster creator admin permissions for AWS Academy Labs
  enable_cluster_creator_admin_permissions = false

  # Skip access entries due to IAM restrictions in AWS Academy Labs
  access_entries = {}

  # Disable automatic IAM role creation
  create_cluster_security_group = false
  create_node_security_group    = false

  # Use default security groups
  cluster_security_group_additional_rules = {}
  node_security_group_additional_rules    = {}

  tags = local.tags
}