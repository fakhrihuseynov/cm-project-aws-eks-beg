output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_cert" {
  description = "Base64 encoded cluster CA"
  value       = module.eks.cluster_ca_certificate
}

output "public_subnet_ids" {
  description = "Public subnet IDs created for the cluster"
  value       = module.vpc.public_subnet_ids
}
