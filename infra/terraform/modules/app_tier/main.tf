resource "aws_instance" "app_server" {
  count = local.current_setup.instance_count

  ami           = local.current_ami
  instance_type = local.current_setup.instance_size

# round robin to distribute created servers on the available app subnets  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [var.app_sg_id]

  user_data_replace_on_change = true
  tags = {
    Name        = "${var.project_name}-${var.environment}-app-${count.index + 1}"
    Environment = var.environment
  }
}