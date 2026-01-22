variable "name" { type = string }
variable "environment" { type = string }
variable "cluster_version" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "node_role_arn" { type = string }
variable "cluster_role_arn" { type = string }
variable "workers_sg_id" { type = string }

resource "aws_eks_cluster" "this" {
  name     = "cm-${var.name}-${var.environment}"
  role_arn = var.cluster_role_arn

  # Kubernetes control-plane version (fall back to 1.27 if empty)
  version = var.cluster_version != "" ? var.cluster_version : "1.35"

  vpc_config {
    subnet_ids = var.public_subnet_ids
    endpoint_public_access = true
  }

  depends_on = []
}

resource "aws_eks_node_group" "ng" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "ng-${var.name}-${var.environment}"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.public_subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t3.medium"]
  ami_type = "BOTTLEROCKET_x86_64"

  remote_access {
    ec2_ssh_key = null
  }
}

output "cluster_name" { value = aws_eks_cluster.this.name }
output "cluster_endpoint" { value = aws_eks_cluster.this.endpoint }
output "cluster_ca_certificate" { value = aws_eks_cluster.this.certificate_authority[0].data }
output "node_group_name" { value = aws_eks_node_group.ng.node_group_name }
