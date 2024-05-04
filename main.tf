#create keypair
resource "aws_key_pair" "harper-keypair" {
  key_name   = "harper-keypair"
  public_key = file("~/.ssh/id_rsa.pub")
}

#create vpc
resource "aws_vpc" "harper-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "harper-vpc"
  }
}

#creating internet gateway for the vpc
resource "aws_internet_gateway" "harper-igw" {
  vpc_id = aws_vpc.harper-vpc.id
  tags = {
    Name = "harper-igw"
  }
}

#create subnet 
resource "aws_subnet" "harper-subnet" {
  vpc_id            = aws_vpc.harper-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "harper-subnet"
  }
}

#creating the route table
resource "aws_route_table" "harper-route-table" {
  vpc_id = aws_vpc.harper-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.harper-igw.id
  }
  tags = {
    Name = "harper-route-table"
  }
}

#associate subnet to route table
resource "aws_route_table_association" "harper-route-table-association" {
  subnet_id      = aws_subnet.harper-subnet.id
  route_table_id = aws_route_table.harper-route-table.id
}

#create the master-node instance
resource "aws_instance" "master-nodes" {
  count             = 2
  ami               = "ami-0440d3b780d96b29d"
  instance_type     = "t2.micro"
  subnet_id     = aws_subnet.harper-subnet.id
  vpc_security_group_ids = [aws_security_group.harper-sg.id]
  key_name = "harper-keypair"
  tags = {
    Name = "Master-Node-${count.index +1}"
  }
}

#create the worker-node instance
resource "aws_instance" "worker-node" {
  ami               = "ami-0440d3b780d96b29d"
  instance_type     = "t2.micro"
  subnet_id     = aws_subnet.harper-subnet.id
  vpc_security_group_ids = [aws_security_group.harper-sg.id]
  key_name = "harper-keypair"
  tags = {
    Name = "Worker-Node"
  }
}

#create the haproxy instance
resource "aws_instance" "haproxy-node" {
  ami               = "ami-0440d3b780d96b29d"
  instance_type     = "t2.micro"
  subnet_id     = aws_subnet.harper-subnet.id
  vpc_security_group_ids = [aws_security_group.harper-sg.id]
  key_name = "harper-keypair"
  tags = {
    Name = "HAProxy-Node"
  }
}

#create the grafana instance
resource "aws_instance" "grafana-node" {
  ami               = "ami-0440d3b780d96b29d"
  instance_type     = "t2.micro"
  subnet_id     = aws_subnet.harper-subnet.id
  vpc_security_group_ids = [aws_security_group.harper-sg.id]
  key_name = "harper-keypair"
  tags = {
    Name = "Grafana-Node"
  }
}

#security group
resource "aws_security_group" "harper-sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.harper-vpc.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Kubernetes API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    description = "Allow etcd"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Kubelet, Kube-scheduler and Kube-controller-manager"
    from_port   = 10250
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "Allow NodePort Services"
    from_port   = 30000
    to_port     = 32767
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
    Name = "harper-sg"
  }
}