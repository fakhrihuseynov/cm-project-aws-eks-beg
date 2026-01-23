#!/usr/bin/env bash
set -euo pipefail

echo "Running account-wide resource scan across all regions..."

# REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)
REGIONS="<your_deployed_regions_here>" # e.g., us-east-1 us-west-2

for r in $REGIONS; do
  echo
  echo "=== REGION: $r ==="

  echo "- EC2 instances:"
  aws ec2 describe-instances --region "$r" --query "Reservations" --output json || true

  echo "- EBS volumes:"
  aws ec2 describe-volumes --region "$r" --query "Volumes" --output json || true

  echo "- Elastic IPs:"
  aws ec2 describe-addresses --region "$r" --query "Addresses" --output json || true

  echo "- NAT Gateways:"
  aws ec2 describe-nat-gateways --region "$r" --query "NatGateways" --output json || true

  echo "- VPC Endpoints:"
  aws ec2 describe-vpc-endpoints --region "$r" --query "VpcEndpoints" --output json || true

  echo "- Load Balancers (ALB/NLB):"
  aws elbv2 describe-load-balancers --region "$r" --query "LoadBalancers" --output json || true

  echo "- RDS instances:"
  aws rds describe-db-instances --region "$r" --query "DBInstances" --output json || true

  echo "- EFS:"
  aws efs describe-file-systems --region "$r" --query "FileSystems" --output json || true

  echo "- S3 Buckets:"
  aws s3api list-buckets --query "Buckets[].Name" --output text | xargs -I {} aws s3api get-bucket-location --bucket {} --region "$r" --query "LocationConstraint" --output text || true

  echo "- Autoscaling Groups:"
  aws autoscaling describe-auto-scaling-groups --region "$r" --query "AutoScalingGroups" --output json || true

  echo "- EKS Clusters:"
  aws eks list-clusters --region "$r" --query "clusters" --output json || true
done

echo
echo "Scan complete. Review output above or redirect to a file for further inspection."