output "address" {
  value       = aws_db_instance.stg_rds.address
  description = "Connect to the database at this endpoint"
}

output "port" {
  value       = aws_db_instance.stg_rds.port
  description = "The port the database is listening on"
}

output "vpcid" {
  value       = aws_vpc.stg_vpc.id
  description = "My VPC Id"
}