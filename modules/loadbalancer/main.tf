# Target Group for ALB (Frontend)
resource "aws_lb_target_group" "web" {
  name        = "${var.environment}-web-tg"
  port        = 80
  protocol    = "HTTP"
  #checkov:skip=CKV_AWS_378:HTTP protocol used for demo target group
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 10
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.environment}-web-tg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Target Group for Backend API
resource "aws_lb_target_group" "backend" {
  name        = "${var.environment}-backend-tg"
  port        = 5000
  protocol    = "HTTP"
  #checkov:skip=CKV_AWS_378:HTTP protocol used for demo target group
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 10
    path                = "/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.environment}-backend-tg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Attachment of ASG to Target Group (only used if not using ECS)
resource "aws_autoscaling_attachment" "web" {
  count                  = var.use_ecs ? 0 : 1
  autoscaling_group_name = var.web_asg_id
  lb_target_group_arn    = aws_lb_target_group.web.arn
}

# Application Load Balancer
resource "aws_lb" "web" {
  name               = "${var.environment}-web-alb"
  internal           = false
  load_balancer_type = "application"
  #checkov:skip=CKV2_AWS_28:WAF not used for demo cost savings
  security_groups    = [var.web_security_group_id]
  subnets            = var.public_subnet_ids
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = true

  #checkov:skip=CKV_AWS_91:Access logging not yet configured
  #checkov:skip=CKV_AWS_131:Dropped invalid headers enabled above


  tags = {
    Name        = "${var.environment}-web-alb"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ALB Listener (default to frontend)
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"
  #checkov:skip=CKV_AWS_2:HTTPS not yet configured (waiting for certificate)

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
  #checkov:skip=CKV_AWS_103:TLS 1.2 not applicable for HTTP listener
  #checkov:skip=CKV2_AWS_20:Redirect to HTTPS not possible without cert
}

# ALB Listener Rule for Backend API
# Routes /api/* requests to the backend target group
resource "aws_lb_listener_rule" "backend_api" {
  listener_arn = aws_lb_listener.web.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/api"]
    }
  }
}

/*

# ALB Listener for HTTPS if u have a certificate from ACM
resource "aws_lb_listener" "web_https" {
  load_balancer_arn = aws_lb.web.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"  # predefined AWS SSL policy
  certificate_arn   = var.alb_certificate_arn       # ACM certificate ARN

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
*/
