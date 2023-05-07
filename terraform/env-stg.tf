data "aws_iam_policy_document" "assume_role_stg" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "juice_shop_stg_ebs_ec2_role" {
  name               = "juice-shop-stg-ebs-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_stg.json
}

resource "aws_iam_role_policy_attachment" "juice_shop_stg_ebs-1" {
  role       = aws_iam_role.juice_shop_ebs_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "juice_shop_stg_ebs-2" {
  role       = aws_iam_role.juice_shop_ebs_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "juice_shop_stg_ebs-3" {
  role       = aws_iam_role.juice_shop_ebs_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_instance_profile" "juice_shop_stg_ebs_iam_instance_profile" {
  name = "juice_shop_stg_ebs_iam_instance_profile"
  role = aws_iam_role.juice_shop_ebs_ec2_role.name
}

resource "aws_s3_bucket" "juice-shop-s3-stg" {
  # checkov:skip=CKV2_AWS_62:Baixo risco
  # checkov:skip=CKV_AWS_145:Baixo risco
  bucket = "juice-shop-s3-stg"
  acl    = "private"
}

resource "aws_s3_bucket_object" "juice_shop_s3_stg_app_options" {
  bucket = aws_s3_bucket.juice-shop-s3-stg.id
  key    = "ebs-app-options.json"
  source = "ebs-app-options.json"
}

resource "aws_elastic_beanstalk_application" "juice_shop_stg_app" {
  name        = "juice-shop-web-stg"
  description = "Juice Shop para o curso de DevSecOps"
}

resource "aws_elastic_beanstalk_environment" "juice_shop_stg_env" {
  name         = "juice-shop-ebs-stg"
  application  = aws_elastic_beanstalk_application.juice_shop_stg_app.name
  cname_prefix = aws_elastic_beanstalk_application.juice_shop_stg_app.name

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
    name      = "MaxSize"
    value     = "1"
  }

}

resource "aws_elastic_beanstalk_application_version" "juice_shop_stg_version" {
  name        = "juice-shop-web-stg"
  application = aws_elastic_beanstalk_application.juice_shop_stg_app.name
  description = "application version created by terraform"
  bucket      = aws_s3_bucket.juice-shop-s3-stg.id
  key         = aws_s3_bucket_object.juice_shop_s3_stg_app_options.id
}
