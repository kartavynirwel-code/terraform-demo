provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "test" {
  bucket = "kartavya-jenkins-test-123"
}
