resource "aws_db_subnet_group" "stg_dbsubnet" {
  name       = "stg_dbsubnetgroup"
  subnet_ids = [aws_subnet.stg_subnet3.id, aws_subnet.stg_subnet4.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "stg_rds" {
  identifier_prefix      = "t101"
  engine                 = "mysql"
  allocated_storage      = 10
  instance_class         = "db.t2.micro"
  db_subnet_group_name   = aws_db_subnet_group.stg_dbsubnet.name
  vpc_security_group_ids = [aws_security_group.stg_sg2.id]
  skip_final_snapshot    = true

  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
}
