data "aws_ami" "amzn2" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = [
    "amzn2-ami-kernel-5.10-*"]
  }

  filter {
    name = "architecture"
    values = [
    "x86_64"]
  }
}

resource "aws_launch_template" "umami-conf" {
  name_prefix   = "umami-server"
  image_id      = data.aws_ami.amzn2.id
  instance_type = "t3.micro"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 10
    }
  }

  iam_instance_profile {
    name = aws_iam_role.umami-server.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [
      aws_security_group.umami-server.id
    ]
  }

  key_name = local.kms-key-name

  tag_specifications {
    resource_type = "instance"
    tags = {
      role  = "umami-server"
    }
  }

}

resource "aws_autoscaling_group" "umami-servers" {
  desired_capacity   = 3
  max_size           = 3
  min_size           = 3
  vpc_zone_identifier = [aws_subnet.umami-subnet-a.id, aws_subnet.umami-subnet-b.id]

  launch_template {
    id      = aws_launch_template.umami-conf.id
    version = "$Latest"
  }
}


resource "aws_instance" "nginx-proxy" {

  ami           = data.aws_ami.amzn2.id 
  instance_type = "t3.micro"

  key_name = local.kms-key-name

  iam_instance_profile = aws_iam_role.nginx-proxy.name

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
    tags = {
      Name = "nginx-proxy"
    }
  }

  vpc_security_group_ids = [
    aws_security_group.nginx-proxy.id
  ]
  
  subnet_id = aws_subnet.umami-subnet-a.id
  associate_public_ip_address = true

  tags = {
    role  = "nginx-proxy"
  }

}
