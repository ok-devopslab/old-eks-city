output "eks_cluster_id" {
  value = module.eks.cluster_id
}

output "cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "worker_iam_role_name" {
  value = module.eks.worker_iam_role_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
