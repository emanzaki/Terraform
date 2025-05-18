variable "ami" {
    description = "value of ami"
    type        = string
}
variable "instance_type" {
    description = "value of instance_type"
    type        = string
}
variable "cidr_block" {
    description = "value of cidr_block"
    type        = map(string)
}
variable "myKey" {
    description = "value of myKey"
    type        = string
}