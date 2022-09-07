terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

#Configuration of AWS provider

provider "aws" {
  region     = "us-east-1"
  profile    = "default"

}

#################################################################
#Create VPC 
#################################################################
resource "aws_vpc" "tf-microservice" {
  cidr_block = "172.0.0.0/16"
  tags = {
    Name        = "Tf-VPC-microservice"
    project     = var.tag_project
    responsible = var.tag_responsible
  }
}

#Create subnet for Public server 1
resource "aws_subnet" "Public-subnet" {
  vpc_id                  = aws_vpc.tf-microservice.id
  cidr_block              = "172.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

}

#Create subnet for Public server 2
resource "aws_subnet" "Public2-subnet" {
  vpc_id                  = aws_vpc.tf-microservice.id
  cidr_block              = "172.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

}



#Create subnet for backend server 1
resource "aws_subnet" "Backend-1-subnet" {
  vpc_id                  = aws_vpc.tf-microservice.id
  cidr_block              = "172.0.11.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
}


#Create subnet for database server
resource "aws_subnet" "Database-subnet" {
  vpc_id                  = aws_vpc.tf-microservice.id
  cidr_block              = "172.0.21.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
}

#################################################################
#Create Internet Gateway 
#################################################################

resource "aws_internet_gateway" "igw_tf_microservice" {
  vpc_id = aws_vpc.tf-microservice.id
}

#################################################################
#Route Tables Internet Gateway
#################################################################
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.tf-microservice.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_tf_microservice.id
  }

}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.Public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.Public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}

#################################################################
#Create Elastic
#################################################################
#Eip for the NAT gateway
resource "aws_eip" "Nat-Elastic-Ip" {
  vpc = true
  tags = {
    Name = "Nat-Elastic-Ip"
  }
}


#################################################################
#Create NAT gateway
#################################################################

resource "aws_nat_gateway" "nat-gateway-public" {
  allocation_id = aws_eip.Nat-Elastic-Ip.id
  subnet_id     = aws_subnet.Public-subnet.id
}

#################################################################
#Route Tables Private Subnets
#################################################################
resource "aws_route_table" "backend-database-rt" {
  vpc_id = aws_vpc.tf-microservice.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gateway-public.id
  }
}
resource "aws_route_table_association" "backend_association" {
  subnet_id      = aws_subnet.Backend-1-subnet.id
  route_table_id = aws_route_table.backend-database-rt.id
}
resource "aws_route_table_association" "database_association" {
  subnet_id      = aws_subnet.Database-subnet.id
  route_table_id = aws_route_table.backend-database-rt.id
}


#################################################################


resource "aws_instance" "tf-public1" {
  ami                    = var.ami
  instance_type          = var.instance_type
  availability_zone      = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.tf-microservice-sg.id]
  subnet_id              = aws_subnet.Public-subnet.id
  key_name               = var.key_pem

  tags = {
    Name        = "Public1-tf"
    project     = var.tag_project
    responsible = var.tag_responsible
  }
  volume_tags = {
    Name        = "Public1-tf"
    project     = var.tag_project
    responsible = var.tag_responsible
  }
  depends_on = [
    aws_subnet.Public-subnet
  ]

}

resource "aws_instance" "tf-public2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  availability_zone      = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.tf-microservice-sg.id]
  subnet_id              = aws_subnet.Public-subnet.id
  key_name               = var.key_pem

  tags = {
    Name        = "Public2-Tf"
    project     = var.tag_project
    responsible = var.tag_responsible
  }
  volume_tags = {
    Name        = "Public2-Tf"
    project     = var.tag_project
    responsible = var.tag_responsible
  }
  depends_on = [
    aws_subnet.Public-subnet
  ]


}
resource "aws_instance" "tf-backend1" {
  ami                    = var.ami
  instance_type          = var.instance_type
  availability_zone      = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.tf-microservice-sg.id]
  subnet_id              = aws_subnet.Backend-1-subnet.id
  key_name               = var.key_pem

  tags = {
    Name        = "Backend-Tf"
    project     = var.tag_project
    responsible = var.tag_responsible
  }
  volume_tags = {
    Name        = "Backend-Tf"
    project     = var.tag_project
    responsible = var.tag_responsible
  }
  depends_on = [
    aws_subnet.Backend-1-subnet,
    aws_instance.tf-public1
  ]



}
resource "aws_instance" "tf-database" {
  ami                    = var.ami
  instance_type          = var.instance_type
  availability_zone      = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.tf-microservice-sg.id]
  subnet_id              = aws_subnet.Database-subnet.id
  key_name               = var.key_pem

  tags = {
    Name        = "Database-Tf"
    project     = var.tag_project
    responsible = var.tag_responsible
  }
  volume_tags = {
    Name        = "Database-Tf"
    project     = var.tag_project
    responsible = var.tag_responsible
  }
  depends_on = [
    aws_subnet.Database-subnet
  ]

}

############################################################
#Instances Provisioning
############################################################
resource "null_resource" "necessary-files" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "file" {

    source      = "public-proyect.pem"
    destination = "/home/ubuntu/public-proyect.pem"

    connection {
      type        = var.connection_ssh
      user        = var.connection_user
      private_key = file("public-proyect.pem")
      host        = aws_instance.tf-public1.public_ip

    }
  }
  provisioner "file" {

    source      = "public-proyect.pem"
    destination = "/home/ubuntu/public-proyect.pem"

    connection {
      type        = var.connection_ssh
      user        = var.connection_user
      private_key = file("public-proyect.pem")
      host        = aws_instance.tf-public2.public_ip

    }
  }
  provisioner "file" {

    source      = "frontend.yml"
    destination = "/home/ubuntu/frontend.yml"

    connection {
      type        = var.connection_ssh
      user        = var.connection_user
      private_key = file("public-proyect.pem")
      host        = aws_instance.tf-public1.public_ip

    }
  }
  provisioner "file" {

    source      = "frontend.yml"
    destination = "/home/ubuntu/frontend.yml"

    connection {
      type        = var.connection_ssh
      user        = var.connection_user
      private_key = file("public-proyect.pem")
      host        = aws_instance.tf-public2.public_ip

    }
  }
  provisioner "file" {

    source      = "d-frontend.yml"
    destination = "/home/ubuntu/d-frontend.yml"

    connection {
      type        = var.connection_ssh
      user        = var.connection_user
      private_key = file("public-proyect.pem")
      host        = aws_instance.tf-public1.public_ip

    }
  }
  provisioner "file" {

    source      = "d-frontend.yml"
    destination = "/home/ubuntu/d-frontend.yml"

    connection {
      type        = var.connection_ssh
      user        = var.connection_user
      private_key = file("public-proyect.pem")
      host        = aws_instance.tf-public2.public_ip

    }
  }

  provisioner "file" {

    source      = "backend.yml"
    destination = "/home/ubuntu/backend.yml"


    connection {
      type                = var.connection_ssh
      bastion_host        = aws_instance.tf-public1.public_ip
      bastion_user        = var.connection_user
      bastion_private_key = file("public-proyect.pem")
      host                = aws_instance.tf-backend1.private_ip
      user                = var.connection_user
      private_key         = file("public-proyect.pem")
    }
  }
  provisioner "file" {

    source      = "d-backend.yml"
    destination = "/home/ubuntu/d-backend.yml"


    connection {
      type                = var.connection_ssh
      bastion_host        = aws_instance.tf-public1.public_ip
      bastion_user        = var.connection_user
      bastion_private_key = file("public-proyect.pem")
      host                = aws_instance.tf-backend1.private_ip
      user                = var.connection_user
      private_key         = file("public-proyect.pem")
    }

  }

  provisioner "file" {

    source      = "database.yml"
    destination = "/home/ubuntu/database.yml"


    connection {
      type                = var.connection_ssh
      bastion_host        = aws_instance.tf-public1.public_ip
      bastion_user        = var.connection_user
      bastion_private_key = file("public-proyect.pem")
      host                = aws_instance.tf-database.private_ip
      user                = var.connection_user
      private_key         = file("public-proyect.pem")
    }
  }
  provisioner "file" {

    source      = "d-database.yml"
    destination = "/home/ubuntu/d-database.yml"


    connection {
      type                = var.connection_ssh
      bastion_host        = aws_instance.tf-public1.public_ip
      bastion_user        = var.connection_user
      bastion_private_key = file("public-proyect.pem")
      host                = aws_instance.tf-database.private_ip
      user                = var.connection_user
      private_key         = file("public-proyect.pem")
    }
  }
  depends_on = [aws_instance.tf-public1, aws_instance.tf-public2, aws_instance.tf-backend1, aws_instance.tf-database]

}
############################################################
#Instances Provisioning
############################################################

resource "null_resource" "frontend1_provisioning" {
  triggers = {
    always_run = "${timestamp()}"
    order = null_resource.necessary-files.id
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y ansible",
      "sudo apt -y install python",
      "sudo ansible-playbook frontend.yml -u ubuntu"

    ]
    connection {
      type        = var.connection_ssh
      host        = aws_instance.tf-public1.public_ip
      user        = var.connection_user
      private_key = file("public-proyect.pem")
    }
  }

  depends_on = [aws_instance.tf-public1]

}
resource "null_resource" "frontend2_provisioning" {
  triggers = {
    always_run = "${timestamp()}"
    order = null_resource.necessary-files.id
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y ansible",
      "sudo apt -y install python",
      "sudo ansible-playbook frontend.yml -u ubuntu"

    ]
    connection {
      type        = var.connection_ssh
      host        = aws_instance.tf-public2.public_ip
      user        = var.connection_user
      private_key = file("public-proyect.pem")
    }
  }

  depends_on = [aws_instance.tf-public2]

}

resource "null_resource" "backend_provisioning" {
  triggers = {
    always_run = "${timestamp()}"
    order = null_resource.necessary-files.id
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y ansible",
      "sudo apt -y install python",
      "sudo ansible-playbook backend.yml -u ubuntu"

    ]
    connection {
      type                = var.connection_ssh
      bastion_host        = aws_instance.tf-public1.public_ip
      bastion_user        = var.connection_user
      bastion_private_key = file("public-proyect.pem")
      host                = aws_instance.tf-backend1.private_ip
      user                = var.connection_user
      private_key         = file("public-proyect.pem")
    }
  }

  depends_on = [aws_instance.tf-backend1]

}

resource "null_resource" "database_provisioning" {
  triggers = {
    always_run = "${timestamp()}"
    order = null_resource.necessary-files.id
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y ansible",
      "sudo apt -y install python",
      "sudo ansible-playbook database.yml -u ubuntu"

    ]
    connection {
      type                = var.connection_ssh
      bastion_host        = aws_instance.tf-public1.public_ip
      bastion_user        = var.connection_user
      bastion_private_key = file("public-proyect.pem")
      host                = aws_instance.tf-database.private_ip
      user                = var.connection_user
      private_key         = file("public-proyect.pem")
    }
  }

  depends_on = [aws_instance.tf-database]

}




############################################################
#Instances Deployment 
############################################################
resource "null_resource" "frontend1_deployment" {
  triggers = {
    order      = null_resource.frontend1_provisioning.id
    always_run = "${timestamp()}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo ansible-playbook d-frontend.yml --extra-vars=\"backip=${aws_instance.tf-backend1.private_ip}\" -u ubuntu"
    ]
    connection {
      type        = var.connection_ssh
      host        = aws_instance.tf-public1.public_ip
      user        = var.connection_user
      private_key = file("public-proyect.pem")
    }
  }

  depends_on = [aws_instance.tf-public1]

}
resource "null_resource" "frontend2_deployment" {
  triggers = {
    order      = null_resource.frontend2_provisioning.id
    always_run = "${timestamp()}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo ansible-playbook d-frontend.yml --extra-vars=\"backip=${aws_instance.tf-backend1.private_ip}\" -u ubuntu"
    ]
    connection {
      type        = var.connection_ssh
      host        = aws_instance.tf-public2.public_ip
      user        = var.connection_user
      private_key = file("public-proyect.pem")
    }
  }

  depends_on = [aws_instance.tf-public2]

}
resource "null_resource" "backend_deployment" {
  triggers = {
    order      = null_resource.backend_provisioning.id
    always_run = "${timestamp()}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo ansible-playbook d-backend.yml --extra-vars=\"backip=${aws_instance.tf-backend1.private_ip} databaseip=${aws_instance.tf-database.private_ip}\" -u ubuntu"
    ]
    connection {
      type                = var.connection_ssh
      bastion_host        = aws_instance.tf-public1.public_ip
      bastion_user        = var.connection_user
      bastion_private_key = file("public-proyect.pem")
      host                = aws_instance.tf-backend1.private_ip
      user                = var.connection_user
      private_key         = file("public-proyect.pem")
    }
  }

  depends_on = [aws_instance.tf-backend1]

}

resource "null_resource" "database_deployment" {
  triggers = {
    order      = null_resource.database_provisioning.id
    always_run = "${timestamp()}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo ansible-playbook d-database.yml -u ubuntu"
    ]
    connection {
      type                = var.connection_ssh
      bastion_host        = aws_instance.tf-public1.public_ip
      bastion_user        = var.connection_user
      bastion_private_key = file("public-proyect.pem")
      host                = aws_instance.tf-database.private_ip
      user                = var.connection_user
      private_key         = file("public-proyect.pem")
    }
  }

  depends_on = [aws_instance.tf-database]

}


############################################################
#Seciruty Group
############################################################
resource "aws_security_group" "tf-microservice-sg" {
  name   = "tf-microservice-sg"
  vpc_id = aws_vpc.tf-microservice.id

  #Allow ssh
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Allow 443
  ingress {
    description = "Port 443 to http"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow 80
  ingress {
    description = "Port 80 to http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Allow 8000 Frontend
  ingress {
    description = "Port 8000 to http"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Allow 8080 to 8083 for APIS
  ingress {
    description = "Port 8080 - 8083 to http"
    from_port   = 8080
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow 6379 for  Redis
  ingress {
    description = "Port 6379 to http"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Allow 9411 for  Zpkin
  ingress {
    description = "Port 9411 to http"
    from_port   = 9411
    to_port     = 9411
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
#################################################################
#Create Load Balancer
#################################################################
resource "aws_lb" "external-elb" {
  name               = "tf-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tf-microservice-sg.id]
  subnets            = [aws_subnet.Public-subnet.id, aws_subnet.Public2-subnet.id]

  depends_on = [
    aws_instance.tf-public1, aws_instance.tf-public2
  ]
}

resource "aws_lb_target_group" "external-elb" {
  name     = "ALB-TG"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.tf-microservice.id
}

resource "aws_lb_target_group_attachment" "external-elb1" {
  target_group_arn = aws_lb_target_group.external-elb.arn
  target_id        = aws_instance.tf-public1.id
  port             = 8080

  depends_on = [
    aws_instance.tf-public1
  ]
}
resource "aws_lb_target_group_attachment" "external-elb2" {
  target_group_arn = aws_lb_target_group.external-elb.arn
  target_id        = aws_instance.tf-public2.id
  port             = 8080

  depends_on = [
    aws_instance.tf-public2
  ]
}


resource "aws_lb_listener" "external-elb" {
  load_balancer_arn = aws_lb.external-elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external-elb.arn
  }
}