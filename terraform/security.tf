resource "aws_security_group" "umami-server" {
  name        = "umami-server"
  description = "Allow required port to manage and use a umami server"
  vpc_id      = aws_vpc.umami-vpc.id

  egress {
    description      = "Allow all outgoing connection"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "Allow ssh only to authorized endpoints defined in variables"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.ssh-whitelist
  }

  ingress {
    description = "Allow connection to node server"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "umami-server"
  }
}

resource "aws_security_group" "umami-db" {
  name        = "umami-db"
  description = "Allow umami server to access the RDS db"
  vpc_id      = aws_vpc.umami-vpc.id

  egress {
    description      = "Allow all outgoing connection"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description        = "Allow psql connection"
    from_port          = 5432
    to_port            = 5432
    protocol           = "tcp"
    security_groups = [aws_security_group.umami-server.id]
  }

  tags = {
    Name = "umami-db"
  }
}


resource "aws_security_group" "nginx-proxy" {
  name        = "nginx-proxy"
  description = "Allow access to nginx proxy from the internet"
  vpc_id      = aws_vpc.umami-vpc.id

  egress {
    description      = "Allow all outgoing connection"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "Allow ssh only to authorized endpoints defined in variables"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.ssh-whitelist
  }

  ingress {
    description        = "Allow https connection"
    from_port          = 443
    to_port            = 443
    protocol           = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nginx-proxy"
  }
}

resource "aws_iam_role" "umami-server" {
  name = "umami-server"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "umami-server"
  }
}

resource "aws_iam_policy" "umami_db_ro" {
  name        = "umami_db_ro"
  description = "Allow limited ro access to RDS umami db"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "rds:ListTagsForResource",
                "rds:DescribeDBInstances"
            ],
            "Resource": "${aws_db_instance.umami-db.arn}"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.umami-server.name
  policy_arn = aws_iam_policy.umami_db_ro.arn
}

resource "aws_iam_instance_profile" "umami-server" {
  name = "umami-server"
  role = aws_iam_role.umami-server.name
}

resource "aws_iam_role" "nginx-proxy" {
  name = "nginx-proxy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "nginx-proxy"
  }
}

resource "aws_iam_instance_profile" "nginx-proxy" {
  name = "nginx-proxy"
  role = aws_iam_role.nginx-proxy.name
}

## RDS Password

resource "random_password" "umami_db_password" {
  length  = 16
  special = true
  override_special = "!#$%&+-_(){}=<>,.^~:;"
}

resource "aws_secretsmanager_secret" "umami_db_password" {
  name = "umami_db_password"
}

resource "aws_secretsmanager_secret_version" "umami_db_password" {
  secret_id     = aws_secretsmanager_secret.umami_db_password.id
  secret_string = random_password.umami_db_password.result
}
