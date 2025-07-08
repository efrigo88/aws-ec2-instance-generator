resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "ec2-cloudwatch-role-${var.project_name}-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "cloudwatch_logs_policy" {
  name        = "cloudwatch-logs-policy-${var.project_name}-${var.environment}"
  description = "Policy for EC2 to write logs to CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_logs_policy" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs_policy.arn
}

resource "aws_iam_instance_profile" "ec2_cloudwatch_instance_profile" {
  name = "ec2-cloudwatch-instance-profile-${var.project_name}-${var.environment}"
  role = aws_iam_role.ec2_cloudwatch_role.name
}
