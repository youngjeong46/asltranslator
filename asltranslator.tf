provider "aws" { 
    profile = var.profile
    region = var.region
}

data "aws_caller_identity" "current"{}

locals{
    user_string = "${data.aws_caller_identity.current.account_id}-${lower(data.aws_caller_identity.current.user_id)}"
}

resource "aws_s3_bucket" "blog_site"{
    bucket="young-jeong-blog-site"
    
    website {
        index_document="index.html"
        error_document="error.html"
    }
}

resource "aws_cloudfront_origin_access_identity" "blog_oai"{
    comment ="OAI created for the Blog S3 bucket"
}

resource "aws_cloudfront_distribution" "site_distribution" {
    aliases = [
        "www.youngsjeong.com",
        "youngsjeong.com"
    ]
    origin {
        domain_name = "${aws_s3_bucket.blog_site.bucket_domain_name}"
        origin_id = "${var.s3_origin_id}"
        s3_origin_config {
            origin_access_identity = "${aws_cloudfront_origin_access_identity.blog_oai.cloudfront_access_identity_path}"
        }
    }

    enabled             = true
    comment             = "CF Distro for Blog site"
    default_root_object = "index.html"

    default_cache_behavior {
        allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = "${var.s3_origin_id}"

        forwarded_values {
            query_string = false

            cookies {
                forward = "none"
            }
        }

        viewer_protocol_policy = "redirect-to-https"
    }

    restrictions {
        geo_restriction {
            restriction_type = "whitelist"
            locations        = ["US", "CA", "GB", "DE"]
        }
    }

    tags = {
        Environment = "production"
    }

    viewer_certificate {
        acm_certificate_arn = var.acm_certificate_arn
        cloudfront_default_certificate = false
        minimum_protocol_version = "TLSv1.1_2016" 
        ssl_support_method = "sni-only" 
    }
}

resource "aws_s3_bucket" "asl_data_train"{
    bucket="sagemaker-asl-train-${local.user_string}"
}

resource "aws_s3_bucket" "asl_data_model"{
    bucket="sagemaker-asl-model-${local.user_string}"
}

data "aws_iam_policy_document" "asl-sagemaker-assume-role-policy"{
    statement{
        actions=["sts:AssumeRole"]

        principals {
            type = "Service"
            identifiers = ["sagemaker.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "asl-sagemaker-role"{
    name="asl-sgmkr-role-${local.user_string}"
    path = "/"
    assume_role_policy = "${data.aws_iam_policy_document.asl-sagemaker-assume-role-policy.json}"
}

resource "aws_iam_policy_attachment" "asl-sagemaker-attach"{
    name = "asl-sagemaker-attachment"
    roles = ["${aws_iam_role.asl-sagemaker-role.name}"]
    policy_arn = var.sagemakerfullaccess
}

resource "aws_sagemaker_notebook_instance" "asl_translator_notebook" {
    name = "asl-translator-${local.user_string}"
    role_arn = "${aws_iam_role.asl-sagemaker-role.arn}"
    instance_type = "ml.p2.xlarge"
}