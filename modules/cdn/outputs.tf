output "cloudfront_domain_name" {
  description = "The CloudFront distribution domain name"
  value       = length(aws_cloudfront_distribution.this) > 0 ? aws_cloudfront_distribution.this[0].domain_name : ""
}
output "cloudfront_id" {
  description = "CloudFront distribution ID"
  value       = length(aws_cloudfront_distribution.this) > 0 ? aws_cloudfront_distribution.this[0].id : ""
}
