output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnets" {
  value = aws_subnet.app_public.*.id
}

output "public_subnets_cidr" {
  value = aws_subnet.app_public.*.cidr_block
}

output "private_subnets" {
  value = aws_subnet.app_private.*.id
}

output "private_subnets_arn" {
  value = aws_subnet.app_private.*.arn
}

output "private_subnets_cidr" {
  value = aws_subnet.app_private.*.cidr_block
}

output "db_subnets" {
  value = aws_subnet.db_private.*.id
}

output "db_subnets_cidr" {
  value = aws_subnet.db_private.*.cidr_block
}

output "eks_cluster_name" {
  value = local.cluster_name
}

output "random_id" {
  value = random_integer.id.result
}
