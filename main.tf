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




resource "aws_security_group" "allow_ssh_http" {
	name = "allow_ssh_http"
	description = "Allow SSH and HTTP inbound traffic and all outbound traffic"
	 vpc_id = "vpc-01d467e051bc46e75"
	tags = {
		Name = "allow-ssh-http"
	}
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
	security_group_id = aws_security_group.allow_ssh_http.id
	cidr_ipv4 = "0.0.0.0/0"
	ip_protocol = "-1" # all ports
}
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
	security_group_id = aws_security_group.allow_ssh_http.id
	cidr_ipv4 = "0.0.0.0/0"
	ip_protocol = "tcp"
	from_port = 8080
	to_port = 8081
}
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
	security_group_id = aws_security_group.allow_ssh_http.id
	cidr_ipv4 = "0.0.0.0/0"
	ip_protocol = "tcp"
	from_port = 22
	to_port = 22
}


resource "aws_instance" "tf-web-server" {
	ami = "ami-080e1f13689e07408"
	instance_type = "t2.micro"
	key_name = "vockey"
	subnet_id = "subnet-0dcea9e7ff3ff76bc"
	vpc_security_group_ids = [aws_security_group.allow_ssh_http.id] 
	associate_public_ip_address = "true"

	user_data <<-EOF
		#!/bin/bash
		
		sudo apt-get install docker-ce docker-ce-cli containerd.io

		sudo mkdir -p /usr/local/lib/docker/cli-plugins
		sudo curl -sL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m) -o /usr/local/lib/docker/cli-plugins/docker-compose

		sudo chown root:root /usr/local/lib/docker/cli-plugins/docker-compose
		sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

		sudo snap install docker
		sudo apt-install default-jdk

		sudo apt update
		sudo apt install maven

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
		cd ../a1-wiktor0072/backend
		sudo docker build -t backend:v1 -t backend:latest .
		cd ..
		sudo docker compose up -d


		EOF
	

	user_data_replace_on_change = true
	tags = {
		Name = "Tic-tac-toe-Webserver"
	}
}
