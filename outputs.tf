output "kinesis_stream_arn" {
  description = "ARN of the Kinesis Stream"
  value       = aws_kinesis_stream.example.arn
}

output "iam_policy_arn" {
  description = "ARN of the IAM policy"
  value       = aws_iam_policy.example.arn
}
