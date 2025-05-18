#EC2 instance
ami = "ami-0953476d60561c955"
instance_type = "t2.micro"
#VPC
#Subnet
cidr_block = {
    "vpc" = "10.0.0.0/16"
    "subnet1" = "10.0.0.0/24"
    "subnet2" = "10.0.1.0/24"
    "anyone" = "0.0.0.0/0"
}
myKey = "myKey"