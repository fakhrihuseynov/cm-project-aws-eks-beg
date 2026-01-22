// Root module declarations so outputs in this folder can reference module outputs.
// Use `-var='environment=dev'` or set `TF_VAR_environment` when running from this folder.

module "vpc" {
	source      = "./modules/vpc"
	region      = var.region
	environment = var.environment
	name        = var.cluster_name
}

module "iam" {
	source      = "./modules/iam"
	name        = var.cluster_name
	environment = var.environment
}

module "eks" {
	source            = "./modules/eks"
	name              = var.cluster_name
	environment       = var.environment
	cluster_version   = var.cluster_version
	vpc_id            = module.vpc.vpc_id
	public_subnet_ids = module.vpc.public_subnet_ids
	node_role_arn     = module.iam.node_role_arn
	cluster_role_arn  = module.iam.cluster_role_arn
	workers_sg_id     = module.vpc.workers_sg_id
}

