data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "juice_shop_ebs_ec2_role" {
  name               = "juice-shop-ebs-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "juice_shop_ebs-1" {
  role       = aws_iam_role.juice_shop_ebs_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "juice_shop_ebs-2" {
  role       = aws_iam_role.juice_shop_ebs_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "juice_shop_ebs-3" {
  role       = aws_iam_role.juice_shop_ebs_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_instance_profile" "juice_shop_ebs_iam_instance_profile" {
  name = "juice_shop_ebs_iam_instance_profile"
  role = aws_iam_role.juice_shop_ebs_ec2_role.name
}

resource "aws_s3_bucket" "juice-shop-s3-prod" {
  # checkov:skip=CKV_AWS_145:Baixo risco
  bucket = "juice-shop-s3-prod"
  acl    = "private"
}

resource "aws_s3_bucket_object" "juice_shop_s3_prod_app_options" {
  bucket = aws_s3_bucket.juice-shop-s3-prod.id
  key    = "ebs-app-options.json"
  source = "ebs-app-options.json"
}

resource "aws_elastic_beanstalk_application" "juice_shop_prod_app" {
  name        = "juice-shop-web-prod"
  description = "Juice Shop para o curso de DevSecOps"
}

resource "aws_elastic_beanstalk_environment" "juice_shop_prod_env" {
  name         = "juice-shop-ebs-prod"
  application  = aws_elastic_beanstalk_application.juice_shop_prod_app.name
  cname_prefix = aws_elastic_beanstalk_application.juice_shop_prod_app.name

  solution_stack_name = "64bit Amazon Linux 2 v3.5.4 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.juice_shop_ebs_iam_instance_profile.arn
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "True"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "2"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "2"
  }

}

resource "aws_elastic_beanstalk_application_version" "juice_shop_prod_version" {
  name        = "juice-shop"
  application = aws_elastic_beanstalk_application.juice_shop_prod_app.name
  description = "application version created by terraform"
  bucket      = aws_s3_bucket.juice-shop-s3-prod.id
  key         = aws_s3_bucket_object.juice_shop_s3_prod_app_options.id
}
