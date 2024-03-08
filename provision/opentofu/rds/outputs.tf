output "url" {
  value = aws_rds_cluster.aurora.endpoint
  description = "The URL of the created RDS cluster"
}
