terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  
}

# Create a VPC
resource "aws_vpc" "cloud-resume-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name    = "cloud-resume-vpc"
  }
}

resource "aws_subnet" "public-subnet-1a" {
    vpc_id            = aws_vpc.cloud-resume-vpc.id
    cidr_block        = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "public-subnet-1a"
    }
}

resource "aws_subnet" "private-subnet-1a" {
    vpc_id            = aws_vpc.cloud-resume-vpc.id
    cidr_block        = "10.0.2.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = false
    tags = {
        Name = "private-subnet-1a"
    }
}

resource "aws_internet_gateway" "cloud-resume-igw" {
  vpc_id = aws_vpc.cloud-resume-vpc.id

  tags = {
    Name = "cloud-resume-igw"
  }
}

resource "aws_route_table" "public-rtb" {
    vpc_id = aws_vpc.cloud-resume-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.cloud-resume-igw.id
    }

    tags = {
        Name = "public-rtb"
    }
}
resource "aws_route_table" "private-rtb" {
    vpc_id = aws_vpc.cloud-resume-vpc.id

    route {
        cidr_block = aws_vpc.cloud-resume-vpc.cidr_block
        gateway_id = "local"
    }
    tags = {
        Name = "private-rtb"
  }
}
  
resource "aws_route_table_association" "public_subnet_association" {
    subnet_id      = aws_subnet.public-subnet-1a.id
    route_table_id = aws_route_table.public-rtb.id
    
}
resource "aws_route_table_association" "private_subnet_association" {
    subnet_id      = aws_subnet.private-subnet-1a.id
    route_table_id = aws_route_table.private-rtb.id

}
#------------------------------------------------VPC ENDS HERE

#Static website creation
resource "aws_s3_bucket" "cloudResume-website" {
  bucket = "cloud-resumedreski"  # Must be globally unique

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Name        = "cloudResume-website"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.cloudResume-website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_public" {
  bucket = aws_s3_bucket.cloudResume-website.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.cloudResume-website.arn}/*"
      }
    ]
  })
}

resource "aws_s3_object" "website_files" {
  for_each = fileset("website", "**")

  bucket = aws_s3_bucket.cloudResume-website.id
  key    = each.value
  source = "website/${each.value}"
  content_type = lookup(
    {
      html = "text/html"
      css  = "text/css"
      js   = "application/javascript"
    },
    split(".", each.value)[length(split(".", each.value)) - 1],
    "application/octet-stream"
  )
  #acl = "public-read"
}


