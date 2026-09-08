# ==============================================================================
# Enterprise Remote State Backend (S3 + DynamoDB Locking)
# ==============================================================================

terraform {
  backend "s3" {
    bucket         = "deepan-tfstate-456508992151-ap-south-1"
    key            = "aws-hub-spoke-network/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
