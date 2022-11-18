# ec2-create-bool 값을 입력 받아 true 일 때는 생성하고 false일 때는 생성하지 않는다. 

variable "ec2-create-bool" {
  type = bool
}

locals {
  nickname = "boseung-study"
}

data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}

resource "aws_instance" "boseung-ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  count = var.ec2-create-bool? 1 : 0
  tags = {
    Name = "${local.nickname}-${count.index}"
  }
}

output "ec2-create" {
  value = ["${aws_instance.boseung-ec2.*.tags.Name}"]
}