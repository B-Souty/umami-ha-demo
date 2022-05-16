data "aws_secretsmanager_secret" "umami_db_password" {
  arn = aws_secretsmanager_secret.umami_db_password.arn
}

data "aws_secretsmanager_secret_version" "umami_db_password" {
  secret_id = data.aws_secretsmanager_secret.umami_db_password.id
}

resource "aws_db_subnet_group" "umami" {
  name       = "umami"
  subnet_ids = [aws_subnet.umami-subnet-a.id, aws_subnet.umami-subnet-b.id]
  tags = {
    Name = "umami"
  }
}

resource "aws_db_instance" "umami-db" {
  allocated_storage = 10
  engine            = "postgres"
  engine_version    = "14.2"
  instance_class    = "db.t4g.micro"
  db_name           = "umami"
  identifier        = "umami"

  db_subnet_group_name   = aws_db_subnet_group.umami.name
  vpc_security_group_ids = [aws_security_group.umami-db.id]

  username = "psqladm"
  password = data.aws_secretsmanager_secret_version.umami_db_password.secret_string

  multi_az            = true
  skip_final_snapshot = true
}
