terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = ">= 5.0"
		}
	}
	required_version = ">= 1.2.0"
}

provider "aws" {
	region = "us-east-1"
}




# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create subnet
resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
}

# Create internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create route table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Associate subnet with route table
resource "aws_route_table_association" "my_subnet_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create security group
resource "aws_security_group" "my_security_group" {
  name        = "my-security-group"
  description = "Allow SSH, HTTP, and custom TicTacToe ports"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_instance" "my_instance" {
	ami = "ami-080e1f13689e07408"
	instance_type = "t2.micro"
	key_name = "vockey"
	subnet_id     = aws_subnet.my_subnet.id
	vpc_security_group_ids = [aws_security_group.my_security_group.id]
	associate_public_ip_address = "true"
	user_data = <<-EOF
		#!/bin/bash
		
		cd home/ubuntu
		sudo apt-get update -y
		sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo snap install docker
        
		sudo mkdir -p /usr/local/lib/docker/cli-plugins
		sudo curl -sL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m) -o /usr/local/lib/docker/cli-plugins/docker-compose

		sudo chown root:root /usr/local/lib/docker/cli-plugins/docker-compose
		sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

		sudo apt-get install -y default-jdk

		sudo apt-get update -y
		sudo apt-get install -y maven

		git clone -b master https://github.com/pwr-cloudprogramming/a1-wiktor0072.git

		cd a1-wiktor0072/backend
		mvn package
		cd ../..

		# Retrieve IP address using metadata script
		API_URL="http://169.254.169.254/latest/api"
		TOKEN=$(curl -X PUT "$API_URL/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 600")
		TOKEN_HEADER="X-aws-ec2-metadata-token: $TOKEN"
		METADATA_URL="http://169.254.169.254/latest/meta-data"
		IP_V4=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/public-ipv4)

		# Replace IP address and URL in JavaScript file
		JS_FILE="a1-wiktor0072/frontend/src/App.js"  # Update with the path to your JavaScript file

		# Replace all occurrences of "localhost" with the IP address
		sed -i "s@localhost@$IP_V4@g" "$JS_FILE"
		echo "IP address replaced in $JS_FILE"

		cd a1-wiktor0072/frontend
		sudo docker build -t frontend:v1 -t frontend:latest .
		cd ../backend
		sudo docker build -t backend:v1 -t backend:latest .
		cd ..
		sudo docker compose up -d


		EOF
	

	user_data_replace_on_change = true
	tags = {
		Name = "Tic-tac-toe-Webserver3"
	}
}
