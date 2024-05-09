# Defne the AWS provider configuration
provider "aws" {
    region = "us-east-1" # Replace with your desired AWS region
}

variable "cidr" {
    default = "10.0.0.0/16"
}

resource "aws_key_pair" "example" {
    key_name = "terraform-demo-akki"
    public_key = file("id_rsa.pub")
}

resource "aws_vpc" "myvpc"{
    cidr_block = var.cidr
}

resource "aws_subnet" "sub1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "RT" {
    vpc_id = aws_vpc.myvpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table_association" "rta1"{
    subnet_id = aws_subnet.sub1.id
    route_table_id = aws_route_table.RT.id
}

resource "aws_security_group" "web5g"{
    name = "web"
    vpc_id = aws_vpc.myvpc.id

    ingress{
        description = "HTTP from VPC"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress{
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]

    }

    tags = {
        Name = "Web-sg"
    }
}

resource "aws_instance" "server" {
    ami = "ami-slkjdflasdfsad"
    instance_type = "t2.micro"
    key_name = aws_key_pair.example.key_name
    vpc_security_group_ids = [aws_security_group.web5g.id]
    subnet_id=aws_subnet.sub1.id

    connection{
        type = "ssh"
        user = "ubuntu"
        private_key = file("id_rsa.pub")
        host = self.public_ip
    }

    #File provisioner to copy the file from local to remote ec2 instance
    provisioner "file"{
        source = "app.py"
        destination = "/home/ubuntu/app.py"
    }

    provisioner "file"{
        source = "run_application.sh"
        destination = "/home/ubuntu/run_application.sh"
    }

    provisioner "remote-exec"{
        inline = [
            "echo 'Hello from the remote instance'",
            "sudo apt update -y",
            "sudo apt-get install -y python3-pip",
            "cd /home/ubuntu",
            "sudo pip3 install flask",
        ]
    }
}
resource "null_resource" "example" {
  # This is a null resource, which doesn't create any infrastructure,
  # but can be used to run provisioners like local-exec.

  # You can define triggers here to force the provisioner to run when certain conditions change.
  triggers = {
    # Trigger the provisioner when the existence of Flask is changed.
    flask_installed = data.null_data_source.flask_installed.result
  }

  # Define a local-exec provisioner block.
  provisioner "local-exec" {
    # Only execute the Python application if Flask is installed.
    command = "bash -c './run_application.sh'"
  }
}

# Data source to check if Flask is installed.
data "null_data_source" "flask_installed" {
  # Execute a local shell command to check if Flask is installed.
  # Adjust the command as needed depending on your environment.
  # This is an example for a Linux-based environment.
  provisioner "local-exec" {
    command = "python3 -c 'import flask'"
  }
}


