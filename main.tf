terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "lab-vpc"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name        = "Public Subnet A"
    Environment = "Dev"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name        = "Public Subnet B"
    Environment = "Dev"
  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name        = "Private Subnet A"
    Environment = "Dev"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name        = "Private Subnet B"
    Environment = "Dev"
  }
}

resource "aws_subnet" "data_app_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name        = "Data App Subnet A"
    Environment = "Dev"
  }
}

resource "aws_subnet" "data_app_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name        = "Data App Subnet B"
    Environment = "Dev"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "lab-igw"
    Environment = "Dev"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "lab-public-rt"
    Environment = "Dev"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "lab-nat-eip"
    Environment = "Dev"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_a.id

  tags = {
    Name        = "lab-nat-gw"
    Environment = "Dev"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "lab-private-rt"
    Environment = "Dev"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "data_a" {
  subnet_id      = aws_subnet.data_app_subnet_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "data_b" {
  subnet_id      = aws_subnet.data_app_subnet_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Allow SSH from my IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["98.167.109.57/32"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

resource "aws_security_group" "private" {
  name        = "private-sg"
  description = "Allow SSH from bastion only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-sg"
  }
}

resource "aws_instance" "bastion" {
  ami                    = "ami-0f3caa1cf4417e51b"
  instance_type          = "t2.micro"
  key_name               = "cloudmedsec-key"
  subnet_id              = aws_subnet.public_subnet_a.id
  vpc_security_group_ids = [aws_security_group.bastion.id]

  tags = {
    Name = "bastion-host"
  }
}

resource "aws_instance" "private" {
  ami                    = "ami-0f3caa1cf4417e51b"
  instance_type          = "t2.micro"
  key_name               = "cloudmedsec-key"
  subnet_id              = aws_subnet.private_subnet_a.id
  vpc_security_group_ids = [aws_security_group.private.id]

  tags = {
    Name = "private-instance"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "cloudmedsec-db-subnet-group"
  subnet_ids = [aws_subnet.data_app_subnet_a.id, aws_subnet.data_app_subnet_b.id]

  tags = {
    Name = "CloudMedSec DB Subnet Group"
  }
}

resource "aws_security_group" "database" {
  name        = "database-sg"
  description = "Allow PostgreSQL from private subnets only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL from private subnets"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24", "10.0.3.0/24"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "database-sg"
  }
}

resource "aws_db_instance" "main" {
  identifier        = "cloudmedsec-db"
  engine            = "postgres"
  engine_version    = "16.6"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_encrypted = true

  db_name  = "cloudmedsec"
  username = "dbadmin"
  password = "ChangeThisPassword123!"

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]

  multi_az            = true
  skip_final_snapshot = true

  tags = {
    Name = "CloudMedSec Database"
  }
}
# S3 Bucket for Patient Medical Records
resource "aws_s3_bucket" "medical_records" {
  bucket = "cloudmedsec-medical-records-${random_string.suffix.result}"

  tags = {
    Name        = "CloudMedSec Medical Records"
    Environment = "Production"
  }
}

# Random suffix for unique bucket names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}


resource "aws_s3_bucket_server_side_encryption_configuration" "medical_records" {
  bucket = aws_s3_bucket.medical_records.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_versioning" "medical_records" {
  bucket = aws_s3_bucket.medical_records.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "medical_imaging" {
  bucket = "cloudmedsec-imaging-${random_string.suffix.result}"

  tags = {
    Name       = "CloudMedSec Medical Imaging"
    Enviroment = "Production"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "medical_imaging" {
  bucket = aws_s3_bucket.medical_imaging.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_versioning" "medical_imaging" {
  bucket = aws_s3_bucket.medical_imaging.id

  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket" "audit_logs" {
  bucket = "cloudmedsec-audit-logs-${random_string.suffix.result}"

  tags = {
    Name        = "CloudMedSec Audit logs"
    Environment = "Production"

  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access - Medical Records
resource "aws_s3_bucket_public_access_block" "medical_records" {
  bucket = aws_s3_bucket.medical_records.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}

# Block public access - Medical Imaging 
resource "aws_s3_bucket_public_access_block" "medical_imagaing" {
  bucket = aws_s3_bucket.medical_imaging.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}

resource "aws_s3_bucket_public_access_block" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}

# Lifecycle policy for medical imaging
resource "aws_s3_bucket_lifecycle_configuration" "medical_imaging" {
  bucket = aws_s3_bucket.medical_imaging.id

  rule {
    id     = "move-old-images-to-glacier"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "DEEP_ARCHIVE"
    }
  }
}


output "medical_imaging_bucket_name" {
  value = aws_s3_bucket.medical_imaging.id

}


# Security Group for ALB  
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTP from the internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# Application Load Balancer 
resource "aws_lb" "main" {
  name               = "cloudmedsec-alb"
  internal           = false # This means that it is internet facing(public can access it. )
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]

  tags = {
    Name = "CloudMedSec ALB"
  }
}


# Target Group for EC2 instances 
resource "aws_lb_target_group" "app" {
  name     = "cloudmedsec-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30

  }
  tags = {
    Name = "CloudMedSec Target Group"

  }
}


# ALB Listener  
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}


# Security Group for App Servers
resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Allow HTTP from ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "app-sg"
  }
}


# App Server 1 in private_subnet_a  

resource "aws_instance" "app1" {
  ami                    = "ami-0f3caa1cf4417e51b"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet_a.id
  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>CloudMedSec App Server 1</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "app-server-1"
  }
}

# App Server 2 in private_subnet_b
resource "aws_instance" "app2" {
  ami                    = "ami-0f3caa1cf4417e51b"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet_b.id
  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>CloudMedSec App Server 2</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "app-server-2"
  }
}


# Attach app1 to target group
resource "aws_lb_target_group_attachment" "app1" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app1.id
  port             = 80

}

# Attach app2 to target group
resource "aws_lb_target_group_attachment" "app2" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app2.id
  port             = 80
}
