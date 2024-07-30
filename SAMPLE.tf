# AWS VPC with multiple subnets and a security group
    resource "aws_vpc" "main" {
      cidr_block = "10.0.0.0/16"
      enable_dns_support = true
      enable_dns_hostnames = true

      tags = {
        Name = "main_vpc"
      }
    }
    resource "aws_subnet" "subnet_a" {
      vpc_id                  = aws_vpc.main.id
      cidr_block              = "10.0.1.0/24"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true

      tags = {
        Name = "subnet_a"
      }
    }
    resource "aws_subnet" "subnet_b" {
      vpc_id                  = aws_vpc.main.id
      cidr_block              = "10.0.2.0/24"
      availability_zone       = "us-east-1b"
      map_public_ip_on_launch = true

      tags = {
        Name = "subnet_b"
      }
    }
    resource "aws_security_group" "allow_all" {
      vpc_id = aws_vpc.main.id

      egress {
        from_port   = 0
        to_port     = 0
        protocol    = "all"
        cidr_blocks = ["0.0.0.0/0"]
      }

      ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "all"
        cidr_blocks = ["0.0.0.0/0"]
      }

      tags = {
        Name = "allow_all_sg"
      }
    }
    resource "aws_instance" "web_server" {
      ami           = "ami-0c55b159cbfafe1f0"
      instance_type = "t2.micro"
      key_name      = "my_key_pair"

      network_interface {
        network_interface_id = aws_network_interface.web_interface.id
        device_index         = 0
      }

      tags = {
        Name = "web_server"
      }

      root_block_device {
        volume_size = 8
        volume_type = "gp2"
      }
    }
    resource "aws_network_interface" "web_interface" {
      subnet_id = aws_subnet.subnet_a.id
      security_groups = [aws_security_group.allow_all.id]
      private_ips = ["10.0.1.10"]

      attachment {
        instance = aws_instance.web_server.id
        device_index = 0
      }
    }
    resource "aws_s3_bucket" "data_bucket" {
      bucket = "my-data-bucket-${random_id.bucket_suffix.hex}"
      acl    = "private"

      versioning {
        enabled = true
      }

      lifecycle_rule {
        id      = "expire-old-versions"
        enabled = true

        noncurrent_version_expiration {
          days = 30
        }
      }

      tags = {
        Name = "data_bucket"
      }
    }
    resource "random_id" "bucket_suffix" {
      byte_length = 8
    }
    resource "aws_iam_role" "lambda_role" {
      name = "lambda_role"

      assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
          {
            Action = "sts:AssumeRole",
            Effect = "Allow",
            Principal = {
              Service = "lambda.amazonaws.com"
            }
          }
        ]
      })

      tags = {
        Name = "lambda_role"
      }
    }
    resource "aws_iam_policy" "lambda_policy" {
      name = "lambda_policy"
      policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
          {
            Action = "s3:GetObject",
            Effect = "Allow",
            Resource = "*"
          }
        ]
      })

      tags = {
        Name = "lambda_policy"
      }
    }
    resource "aws_iam_role_policy_attachment" "lambda_attachment" {
      role       = aws_iam_role.lambda_role.name
      policy_arn  = aws_iam_policy.lambda_policy.arn
    }
    
