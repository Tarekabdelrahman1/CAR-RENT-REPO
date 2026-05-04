resource "aws_instance" "web_server" {
  count = local.current_setup.instance_count

  ami           = local.current_ami
  instance_type = local.current_setup.instance_size
  # round robin to distribute created servers on the avilable subnet
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [var.web_sg_id]

  tags = {
    Name        = "${var.project_name}-${var.environment}-web-${count.index + 1}"
    Environment = var.environment
  }
}
