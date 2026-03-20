resource "aws_security_group" "rds" {
  name   = "petclinic-rds-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "petclinic" {
  name       = "petclinic-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_rds_cluster" "petclinic" {
  cluster_identifier     = "petclinic"
  engine                 = "aurora-mysql"
  engine_version         = "8.0.mysql_aurora.3.12.0"
  engine_mode            = "provisioned"
  database_name          = "petclinic"
  master_username        = var.db_username
  master_password        = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.petclinic.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 4
  }
}

resource "aws_rds_cluster_instance" "petclinic" {
  identifier         = "petclinic-instance-1"
  cluster_identifier = aws_rds_cluster.petclinic.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.petclinic.engine
  engine_version     = aws_rds_cluster.petclinic.engine_version
}

output "rds_endpoint" {
  value = aws_rds_cluster.petclinic.endpoint
}