provider "aws" {
  region = "us-east-1"
  #Keys have been deleted. Created key just for this project.
  access_key = "AKIA3KK5ZWRU3JIRA6PC"
  secret_key = "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"
}

resource "aws_vpc" "web-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Production"
  }
}

resource "aws_internet_gateway" "web-gw" {
  vpc_id = aws_vpc.web-vpc.id
}

resource "aws_route_table" "web-rt" {
  vpc_id = aws_vpc.web-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web-gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.web-gw.id
  }

  tags = {
    Name = "prod"
  }
}

resource "aws_subnet" "web-subnet" {
  vpc_id            = aws_vpc.web-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "web"
  }

}

resource "aws_route_table_association" "web-ass" {
  subnet_id      = aws_subnet.web-subnet.id
  route_table_id = aws_route_table.web-rt.id
}


resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web traffic inbound traffic"
  vpc_id      = aws_vpc.web-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_web"
  }
}

resource "aws_network_interface" "web_server_NIC" {
  subnet_id       = aws_subnet.web-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web_server_NIC.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.web-gw]
}

resource "aws_instance" "ubuntu_webserver" {
  ami               = "ami-04505e74c0741db8d"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "uKey"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web_server_NIC.id
  }

}
