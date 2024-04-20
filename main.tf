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
	

	user_data_replace_on_change = true
	tags = {
		Name = "Tic-tac-toe-Webserver"
	}
}
