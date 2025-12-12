resource "aws_cloudfront_distribution" "this" {
  count = var.environment == "prod" && var.enabled ? 1 : 0

  origin {
    domain_name = var.origin_domain_name
    origin_id   = "ALB-${var.origin_domain_name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # ALB listens on HTTP (80) only
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  #checkov:skip=CKV2_AWS_47:WAF not attached for cost savings
  #checkov:skip=CKV2_AWS_32:Response headers policy default is sufficient
  #checkov:skip=CKV2_AWS_42:Custom SSL not available without domain
  is_ipv6_enabled     = true
  default_root_object = "index.html" # Note: For ALB, this might not be needed if ALB handles routing, but harmless

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"] # ALB needs full methods
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-${var.origin_domain_name}"

    forwarded_values {
      query_string = true
      headers      = [] # Do NOT forward Host header (fixes 504). Let CF use ALB DNS name.
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "allow-all" # Allow HTTP access as requested
  }

  price_class = var.price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # ---------- Viewer Certificate ----------
  # If you have an ACM certificate, uncomment the block below
  # and provide its ARN via variable "certificate_arn"
  #
  # viewer_certificate {
  #   acm_certificate_arn            = var.certificate_arn
  #   ssl_support_method             = "sni-only"
  #   minimum_protocol_version       = "TLSv1.2_2021"
  # }

  # Use default CloudFront certificate if ACM is not provided
  viewer_certificate {
    cloudfront_default_certificate = var.certificate_arn == "" ? true : false
  }

  tags = {
    Environment = var.environment
    Project     = "3-Tier-AWS-Infrastructure"
  }
}
