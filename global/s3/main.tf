
resource "aws_s3_bucket" "global_s3bucket" {
  bucket = "boseung-t101study-tfstate-week3-files"
}

# Enable versioning so you can see the full revision history of your state files
resource "aws_s3_bucket_versioning" "global_s3bucket_versioning" {
  bucket = aws_s3_bucket.global_s3bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "global_dynamodbtable" {
  name         = "terraform-locks-week3-files"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}