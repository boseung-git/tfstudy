# EC2 3개를 생성(count 값에 따라)하고 output으로 각 EC2의 이름을 출력한다.

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
  count = 3
  tags = {
    Name = "${local.nickname}-${count.index}"
  }
}

output "ec2-create" {
  value = ["${aws_instance.boseung-ec2.*.tags.Name}"]
}
