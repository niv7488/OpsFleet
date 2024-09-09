module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id                   = "vpc-1234556abcdef"
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large", "c6.large"]
  }

  eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.xlarge"]

      min_size     = 2
      max_size     = 10
      desired_size = 2
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    # One access entry with a policy associated
    example = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::123456789012:role/something"

      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            namespaces = ["default"]
            type       = "namespace"
          }
        }
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}



resource "aws_iam_role" "karpenter_role" {
  name = "karpenter-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "karpenter.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "karpenter_policy" {
  name = "karpenter-policy"
  role = aws_iam_role.karpenter_role.name
  policy = data.aws_iam_policy_document.karpenter_policy.json
}

data "aws_iam_policy_document" "karpenter_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateInstance",
      "ec2:DescribeInstances",
      "ec2:TerminateInstance",
      "ec2:RunInstances",
      "ec2:ModifyInstanceAttribute",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:DeleteVolume",
      "ec2:CreateVolume",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumeStatus",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DescribeSecurityGroups",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:CreateTag",
      "ec2:DeleteTag",
      "ec2:DescribeTags",
      "ec2:TagResource",
      "ec2:UntagResource"
    ]
    resources = ["*"]
  }
}

module "karpenter" {
  source = "github.com/aws-quickstart/terraform-aws-eks-karpenter"
  eks_cluster_name = var.cluster_name
  karpenter_role_arn = aws_iam_role.karpenter_role.arn
  node_pool_configs = [
    {
      name = "x86-node-pool"
      instance_types = ["m5.large"]
    },
    {
      name = "graviton-node-pool"
      instance_types = ["c6.large"]
    }
  ]
}