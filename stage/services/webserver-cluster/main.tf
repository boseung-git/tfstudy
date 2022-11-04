terraform {
  backend "s3" {
    bucket = "boseung-t101study-tfstate-week3-files"
    key    = "stage/services/webserver-cluster/terraform.tfstate"
    region = "ap-northeast-2"
    dynamodb_table = "terraform-locks-week3-files"
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "boseung-t101study-tfstate-week3-files"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

resource "aws_subnet" "stg_subnet1" {
  vpc_id     = data.terraform_remote_state.db.outputs.vpcid
  cidr_block = "10.10.1.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "t101-subnet1"
  }
}

resource "aws_subnet" "stg_subnet2" {
  vpc_id     = data.terraform_remote_state.db.outputs.vpcid
  cidr_block = "10.10.2.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "t101-subnet2"
  }
}

resource "aws_internet_gateway" "stg_igw" {
  vpc_id = data.terraform_remote_state.db.outputs.vpcid

  tags = {
    Name = "t101-igw"
  }
}

resource "aws_route_table" "stg_rt" {
  vpc_id = data.terraform_remote_state.db.outputs.vpcid

  tags = {
    Name = "t101-rt"
  }
}

resource "aws_route_table_association" "stg_rtassociation1" {
  subnet_id      = aws_subnet.stg_subnet1.id
  route_table_id = aws_route_table.stg_rt.id
}

resource "aws_route_table_association" "stg_rtassociation2" {
  subnet_id      = aws_subnet.stg_subnet2.id
  route_table_id = aws_route_table.stg_rt.id
}

resource "aws_route" "stg_defaultroute" {
  route_table_id         = aws_route_table.stg_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.stg_igw.id
}

resource "aws_security_group" "stg_sg" {
  vpc_id      = data.terraform_remote_state.db.outputs.vpcid
  name        = "T101 SG"
  description = "T101 Study SG"
}

resource "aws_security_group_rule" "stg_sginbound" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.stg_sg.id
}

resource "aws_security_group_rule" "stg_sgoutbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.stg_sg.id
}

data "template_file" "user_data" {
  template = file("user-data.sh")

  vars = {
    server_port = 8080
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }
}

data "aws_ami" "stg_amazonlinux2" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"]
}

resource "aws_launch_configuration" "stg_lauchconfig" {
  name_prefix     = "t101-lauchconfig-"
  image_id        = data.aws_ami.stg_amazonlinux2.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.stg_sg.id]
  associate_public_ip_address = true

  # Render the User Data script as a template
  user_data = templatefile("user-data.sh", {
    server_port = 8080
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  })

  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "stg_asg" {
  name                 = "stg_asg"
  launch_configuration = aws_launch_configuration.stg_lauchconfig.name
  vpc_zone_identifier  = [aws_subnet.mysubnet1.id, aws_subnet.stg_subnet2.id]
  min_size = 2
  max_size = 10
  health_check_type = "ELB"
  target_group_arns = [aws_lb_target_group.myalbtg.arn]

  tag {
    key                 = "Name"
    value               = "terraform-asg"
    propagate_at_launch = true
  }
}

resource "aws_lb" "stg_alb" {
  name               = "t101-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.stg_subnet1.id, aws_subnet.stg_subnet2.id]
  security_groups = [aws_security_group.stg_sg.id]

  tags = {
    Name = "t101-alb"
  }
}

resource "aws_lb_listener" "stg_http" {
  load_balancer_arn = aws_lb.stg_alb.arn
  port              = 8080
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found - T101 Study"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "stg_albtg" {
  name = "t101-alb-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.db.outputs.vpcid

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-299"
    interval            = 5
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "stg_albrule" {
  listener_arn = aws_lb_listener.stg_http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.stg_albtg.arn
  }
}

output "stg_alb_dns" {
  value       = aws_lb.stg_alb.dns_name
  description = "The DNS Address of the ALB"
}