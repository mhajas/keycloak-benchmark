provider "aws" {
  region = var.region
}

resource "aws_vpc" "aurora" {
  cidr_block = "${var.cidr_block_range}.0/24"
  tags = {
    Name = "aurora-vpc-${var.name}"
    AuroraCluster = var.name
  }
}

resource "aws_subnet" "aurora_instance_a" {
  vpc_id = aws_vpc.aurora.id
  cidr_block = "${var.cidr_block_range}.0/25"
  availability_zone = "${var.region}a"
  tags = {
      Name = "aurora-subnet-a-${var.name}"
      AuroraCluster = var.name
  }
}

resource "aws_subnet" "aurora_instance_b" {
  vpc_id = aws_vpc.aurora.id
  cidr_block = "${var.cidr_block_range}.128/25"
  availability_zone = "${var.region}b"
  tags = {
      Name = "aurora-subnet-b-${var.name}"
      AuroraCluster = var.name
  }
}

resource "aws_route_table_association" "aurora_instance_a" {
  subnet_id = aws_subnet.aurora_instance_a.id
  route_table_id = aws_vpc.aurora.main_route_table_id
}

resource "aws_route_table_association" "aurora_instance_b" {
  subnet_id = aws_subnet.aurora_instance_a.id
  route_table_id = aws_vpc.aurora.main_route_table_id
}

resource "aws_db_subnet_group" "aurora" {
  name       = "${var.name}-subnet-group"
  subnet_ids = [aws_subnet.aurora_instance_a.id, aws_subnet.aurora_instance_b.id]
  tags = {
    AuroraCluster = var.name
  }
}

resource "aws_security_group" "aurora" {
  name = "${var.name}-aurora-security-group"
  description = "Aurora DB Security Group"
  vpc_id = aws_vpc.aurora.id
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = var.name
  database_name = "keycloak"
  engine = "aurora-postgresql"
  engine_version = "15.5"
  master_username = "keycloak"
  master_password = "secret99"
  vpc_security_group_ids = [aws_security_group.aurora.id]
  db_subnet_group_name = aws_db_subnet_group.aurora.name
  tags = {
    AuroraCluster = var.name
  }

  skip_final_snapshot = true
}

resource "aws_rds_cluster_instance" "aurora_instance_a" {
  cluster_identifier = aws_rds_cluster.aurora.id
  identifier = "${var.name}-instance-a"
  instance_class = "db.t4g.large"
  engine = "aurora-postgresql"
  availability_zone = aws_subnet.aurora_instance_a.availability_zone
  tags = {
    AuroraCluster = var.name
  }
}

resource "aws_rds_cluster_instance" "aurora_instance_b" {
  cluster_identifier = aws_rds_cluster.aurora.id
  identifier = "${var.name}-instance-b"
  instance_class = "db.t4g.large"
  engine = aws_rds_cluster.aurora.engine
  engine_version = aws_rds_cluster.aurora.engine_version
  availability_zone = aws_subnet.aurora_instance_b.availability_zone
  tags = {
    AuroraCluster = var.name
  }
}
