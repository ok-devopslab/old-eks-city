module "eks-cluster-autoscaler" {
  source                           = "registry.terraform.io/lablabs/eks-cluster-autoscaler/aws"
  version                          = "1.6.1"
  cluster_identity_oidc_issuer     = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  cluster_name                     = data.terraform_remote_state.vpc.outputs.eks_cluster_name
  k8s_namespace                    = "kube-system"
}

#############################################################################################################################################################################

module "eks-kube-state-metrics" {
  source             = "registry.terraform.io/lablabs/eks-kube-state-metrics/aws"
  version            = "0.8.0"
  helm_chart_version = "3.0.3"
  k8s_namespace      = "kube-system"
  settings = {
    replicaCount = 2
  }
}

#############################################################################################################################################################################

resource "helm_release" "aws-ebs-csi-driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  set {
    name  = "serviceAccount.controller.create"
    value = true
  }

  set {
    name  = "serviceAccount.snapshot.create"
    value = true
  }

  set {
    name  = "enableVolumeScheduling"
    value = true
  }

  set {
    name  = "enableVolumeResizing"
    value = true
  }

  set {
    name  = "enableVolumeSnapshot"
    value = true
  }
}

#############################################################################################################################################################################

module "cloudwatch_logs" {
  source                           = "git::https://github.com/DNXLabs/terraform-aws-eks-cloudwatch-logs.git"
  enabled                          = true
  cluster_name                     = data.terraform_remote_state.vpc.outputs.eks_cluster_name
  cluster_identity_oidc_issuer     = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  worker_iam_role_name             = data.terraform_remote_state.eks.outputs.worker_iam_role_name
  region                           = var.aws_region
  helm_chart_version               = "0.1.17"
}

#############################################################################################################################################################################

module "eks-node-problem-detector" {
  source        = "registry.terraform.io/lablabs/eks-node-problem-detector/aws"
  version       = "0.4.0"
  k8s_namespace = "kube-system"
}

#############################################################################################################################################################################

data "kubectl_file_documents" "docs" {
  content = file("metrics-server.yaml")
}

resource "kubectl_manifest" "test" {
  for_each  = data.kubectl_file_documents.docs.manifests
  yaml_body = each.value
}

#############################################################################################################################################################################

module "load_balancer_controller" {
  source                           = "git::https://github.com/DNXLabs/terraform-aws-eks-lb-controller.git"
  cluster_identity_oidc_issuer     = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  cluster_name                     = data.terraform_remote_state.vpc.outputs.eks_cluster_name
  namespace                        = "kube-system"
  helm_chart_version               = "1.4.1"
  settings = {
    replicaCount = 2
    vpcId        = data.terraform_remote_state.vpc.outputs.vpc_id
    region       = var.aws_region
  }
}

#############################################################################################################################################################################

resource "helm_release" "aws-node-termination-handler" {
  name       = "aws-node-termination-handler"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-node-termination-handler"
  namespace  = "kube-system"

  set {
    name  = "enableSpotInterruptionDraining"
    value = "true"
  }
  set {
    name  = "enableRebalanceMonitoring"
    value = "true"
  }
  set {
    name  = "enableScheduledEventDraining"
    value = "false"
  }
}
