variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name (dev|prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster base name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane (set to latest before apply)"
  type        = string
  # Default pinned to latest stable Kubernetes minor version discovered (v1.35.0 -> 1.35)
  default     = "1.35"
}
