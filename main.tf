provider "aws" {
  region = "eu-west-1"
}

terraform {
  backend "s3" {
    bucket = "security-notifications-terraform-state"
    region = "eu-west-1"
    key    = "terraform.tfstate"
  }
}

###########################
# IAM access policy
###########################

resource "aws_iam_role" "mfa_LambdaExecution" {
  name = "mfa-lambdaExecution-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "mfa_LambdaPolicy" {
  name = "mfa-lambdaExecution-policy"
  role = "${aws_iam_role.cp_build_LambdaExecution.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:*"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    }
  ]
}
POLICY
}

###########################
# SNS creation
###########################

resource "aws_sns_topic" "mfa_notifications" {
  name = "cis-mfa-enabled-check"
}

###########################
# Enable cloudtrail
###########################

resource "aws_cloudtrail" "mfa" {
  name                          = "basic-example"
  include_global_service_events = true
}



###########################
# Cloudwatch metric and alarm
###########################

resource "aws_cloudwatch_log_metric_filter" "mfa_enabled_check" {
  name           = "is-mfa-enabled"
  pattern        = ""
  log_group_name = "${aws_cloudwatch_log_group.dada.name}"

  metric_transformation {
    name      = "EventCount"
    namespace = "YourNamespace"
    value     = "1"
  }

resource "aws_cloudwatch_metric_alarm" "foobar" {
  alarm_name                = "terraform-test-foobar5"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []
}

resource "aws_cloudwatch_log_group" "dada" {
  name = "MyApp/access.log"
}

###########################
# Lambda creation
###########################

