module "eks" {
  source                      = "registry.terraform.io/terraform-aws-modules/eks/aws"
  version                     = "17.24.0"
  cluster_name                = data.terraform_remote_state.vpc.outputs.eks_cluster_name
  cluster_version             = var.cluster_version
  vpc_id                      = data.terraform_remote_state.vpc.outputs.vpc_id
  subnets                     = data.terraform_remote_state.vpc.outputs.private_subnets
  enable_irsa                 = true
  workers_additional_policies = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy", "arn:aws:iam::aws:policy/CloudWatchFullAccess", "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM", "arn:aws:iam::aws:policy/AmazonInspector2FullAccess", "arn:aws:iam::aws:policy/AmazonInspectorFullAccess"]
  map_roles = [
    {
      "groups" : ["system:masters"],
      "rolearn" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/EC2_Terraform",
      "username" : "EC2_Terraform"
    },
    {
      "groups" : ["system:masters"],
      "rolearn" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/prod-cross-account-role",
      "username" : "${var.environment}-cross-account-role"
    }
  ]
  map_users = [
    {
      "groups" : ["system:masters"],
      "userarn" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/sahil.bansal",
      "username" : "sahil.bansal"
    }
  ]
  tags = {
    environment                                                                             = var.environment
    "k8s.io/cluster-autoscaler/enabled"                                                     = "TRUE"
    "k8s.io/cluster-autoscaler/${data.terraform_remote_state.vpc.outputs.eks_cluster_name}" = "owned"
    "karpenter.sh/discovery"                                                                = data.terraform_remote_state.vpc.outputs.eks_cluster_name
  }

  workers_group_defaults = {
    root_encrypted      = true
    ebs_optimized       = true
    root_volume_size    = 100
    root_volume_type    = "gp3"
    cpu_credits         = "unlimited"
    additional_userdata = "ulimit -n 4096"
    default_cooldown    = 60
    pre_userdata        = "sudo yum update -y && wget -O - https://inspector-agent.amazonaws.com/linux/latest/install"
    tags = [{
      key                 = "k8s.io/cluster-autoscaler/enabled"
      value               = "TRUE"
      propagate_at_launch = true
      },
      {
        key                 = "k8s.io/cluster-autoscaler/${data.terraform_remote_state.vpc.outputs.eks_cluster_name}"
        value               = "owned"
        propagate_at_launch = true
      },
      {
        key                 = "environment"
        value               = var.environment
        propagate_at_launch = true
      },
      {
        key                 = "Inspector"
        value               = "true"
        propagate_at_launch = true
      }
    ]
  }

  cluster_enabled_log_types     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_log_retention_in_days = var.environment == "dev" ? 3 : 30

  worker_groups_launch_template = [
    {
      name                                     = "on-demand-1"
      override_instance_types                  = ["t2.large", "t3a.large", "t2.xlarge", "t3a.xlarge"]
      asg_min_size                             = var.environment == "dev" ? 2 : 2
      asg_desired_capacity                     = var.environment == "dev" ? 2 : 2
      on_demand_base_capacity                  = var.environment == "dev" ? 2 : 2
      on_demand_percentage_above_base_capacity = var.environment == "dev" ? 100 : 100
      asg_max_size                             = var.environment == "dev" ? 10 : 20
      spot_instance_pools                      = 4
      instance_refresh_enabled                 = true
      instance_refresh_strategy                = "Rolling"
      instance_refresh_min_healthy_percentage  = 100
      kubelet_extra_args                       = "--node-labels=node.kubernetes.io/lifecycle=`curl -s http://169.254.169.254/latest/meta-data/instance-life-cycle`"
    },
    {
      name                                     = "mixed-demand-spot-1"
      override_instance_types                  = ["r6a.large", "r6a.xlarge", "r6a.2xlarge", "c5a.large", "c5a.xlarge", "c5a.2xlarge"]
      asg_min_size                             = var.environment == "dev" ? 1 : 1
      asg_desired_capacity                     = var.environment == "dev" ? 1 : 1
      on_demand_base_capacity                  = var.environment == "dev" ? 0 : 0
      on_demand_percentage_above_base_capacity = var.environment == "dev" ? 0 : 0
      asg_max_size                             = var.environment == "dev" ? 50 : 50
      spot_instance_pools                      = 6
      instance_refresh_enabled                 = true
      instance_refresh_strategy                = "Rolling"
      instance_refresh_min_healthy_percentage  = 100
      kubelet_extra_args                       = "--node-labels=node.kubernetes.io/lifecycle=`curl -s http://169.254.169.254/latest/meta-data/instance-life-cycle`"
    }
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_caller_identity" "current" {}

