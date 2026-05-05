output "app_instance_profile_name" {
  value = aws_iam_instance_profile.app_ec2_profile.name
}

output "app_instance_profile_arn" {
  value = aws_iam_instance_profile.app_ec2_profile.arn
}

output "app_ec2_role_arn" {
  value = aws_iam_role.app_ec2_role.arn
}
output "web_instance_profile_name" {
  value = aws_iam_instance_profile.web_ec2_profile.name
}

output "web_instance_profile_arn" {
  value = aws_iam_instance_profile.web_ec2_profile.arn
}

output "web_ec2_role_arn" {
  value = aws_iam_role.web_ec2_role.arn
}