require "aws-sdk-s3"

bucket_name = "a8c-ci-cache"
object_key = "foo"

bucket = Aws::S3::Bucket.new(bucket_name)
url = bucket.object(object_key).presigned_url(:put)
puts url
