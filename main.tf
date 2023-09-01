resource "aws_kinesis_stream" "example" {
  name             = var.kinesis_stream_name
  shard_count      = 1
}

resource "aws_iam_policy" "example" {
  name        = "${var.user_name}policy"
  description = "IAM policy for Blumira"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "kinesis:*",
        Effect = "Allow",
        Resource = aws_kinesis_stream.example.arn,
      },
    ],
  })
}

resource "aws_iam_user" "example" {
  name = var.user_name
}

resource "aws_iam_user_policy_attachment" "example" {
  policy_arn = aws_iam_policy.example.arn
  user       = aws_iam_user.example.name
}

resource "aws_iam_role" "cwl_to_kinesis_role" {
  name = "${var.namespace}BlumiraCWLtoKinesisDataStreamRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "cloudwatch.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_iam_policy" "cwl_to_kinesis_policy" {
  name        = "${var.namespace}PermissionPolicyForCWLToDataStream"
  description = "IAM policy for CloudWatch Logs to Kinesis"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "kinesis:Put*",
        Effect = "Allow",
        Resource = aws_kinesis_stream.example.arn,
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "cwl_to_kinesis_policy_attachment" {
  policy_arn = aws_iam_policy.cwl_to_kinesis_policy.arn
  role       = aws_iam_role.cwl_to_kinesis_role.name
}

resource "aws_iam_role" "event_service_role" {
  name = "${var.namespace}BlumiraEventServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_iam_policy" "event_service_policy" {
  name        = "${var.namespace}PermissionPolicyEventService"
  description = "IAM policy for Event Service"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "kinesis:Put*",
        Effect = "Allow",
        Resource = aws_kinesis_stream.example.arn,
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "event_service_policy_attachment" {
  policy_arn = aws_iam_policy.event_service_policy.arn
  role       = aws_iam_role.event_service_role.name
}

resource "aws_cloudwatch_log_group" "example" {
  name = "${var.namespace}BlumiraCWLogs"
}

resource "aws_cloudwatch_event_rule" "cloudwatch_logs_rule" {
  name        = "${var.namespace}BlumiraCWLogs"
  description = "CloudWatch Logs rule"
  event_pattern = jsonencode({
    source = ["aws.logs"],
  })
}

resource "aws_cloudwatch_event_target" "cloudwatch_logs_target" {
  rule      = aws_cloudwatch_event_rule.cloudwatch_logs_rule.name
  target_id = "CWTarget1"
  arn       = aws_kinesis_stream.example.arn
  role_arn  = aws_iam_role.event_service_role.arn
}


resource "aws_cloudwatch_log_subscription_filter" "example" {
  name            = "${var.namespace}BlumiraCWFilter"
  log_group_name  = aws_cloudwatch_log_group.example.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.example.arn
  role_arn        = aws_iam_role.cwl_to_kinesis_role.arn
}
