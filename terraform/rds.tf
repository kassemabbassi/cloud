# Subnet Group — dire à RDS dans quels sous-réseaux se placer
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name    = "${var.project_name}-db-subnet-group"
    Project = var.project_name
  }
}

# Instance RDS
resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-db"
  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    Name    = "${var.project_name}-db"
    Project = var.project_name
  }
}