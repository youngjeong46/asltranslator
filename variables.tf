variable "acm_certificate_arn" {
    default = "arn:aws:acm:us-east-1:661554271967:certificate/5649a7b2-650b-4e95-8c31-84e699953a76"
}
variable "profile"{
    default = "default"
}
variable "region" {
    default = "us-east-2"
} 
variable "s3_origin_id" {
    default = "myS3Origin"
}

variable "sagemakerfullaccess" {
    default = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}