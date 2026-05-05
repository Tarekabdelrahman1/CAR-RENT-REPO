locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_iam_role" "app_ec2_role" {
  name = "${local.name_prefix}-app-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-app-ec2-role"
    Tier = "app"
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "read_db_secret" {
  name = "${local.name_prefix}-read-db-secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.db_secret_arn
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-read-db-secret"
    Tier = "app"
  })
}

resource "aws_iam_role_policy_attachment" "read_db_secret" {
  role       = aws_iam_role.app_ec2_role.name
  policy_arn = aws_iam_policy.read_db_secret.arn
}

resource "aws_iam_instance_profile" "app_ec2_profile" {
  name = "${local.name_prefix}-app-ec2-profile"
  role = aws_iam_role.app_ec2_role.name

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-app-ec2-profile"
    Tier = "app"
  })
}
resource "aws_iam_role" "web_ec2_role" {
  name = "${local.name_prefix}-web-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-web-ec2-role"
    Tier = "web"
  })
}

resource "aws_iam_role_policy_attachment" "web_ssm" {
  role       = aws_iam_role.web_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "web_ec2_profile" {
  name = "${local.name_prefix}-web-ec2-profile"
  role = aws_iam_role.web_ec2_role.name

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-web-ec2-profile"
    Tier = "web"
  })
}