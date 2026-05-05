resource "aws_s3_bucket" "ansible_ssm" {
  bucket = var.bucket_name

  tags = {
    Name        = "${var.project_name}-${var.environment}-ansible-ssm"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "ansible-ssm"
  }
}

resource "aws_s3_bucket_public_access_block" "ansible_ssm" {
  bucket = aws_s3_bucket.ansible_ssm.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ansible_ssm" {
  bucket = aws_s3_bucket.ansible_ssm.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Important for Ansible SSM:
# Keep versioning disabled/suspended for this bucket.
# Ansible uploads temporary module files to S3 and deletes them after the run.
# If versioning is enabled, deleted files may remain in version history.
resource "aws_s3_bucket_versioning" "ansible_ssm" {
  bucket = aws_s3_bucket.ansible_ssm.id

  versioning_configuration {
    status = "Suspended"
  }
}