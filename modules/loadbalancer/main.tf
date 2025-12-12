# Target Group for ALB (Frontend)
resource "aws_lb_target_group" "web" {
  name        = "${var.environment}-web-tg"
  port        = 80
  protocol    = "HTTP"
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
  }
}

# Target Group for Backend API
resource "aws_lb_target_group" "backend" {
  name        = "${var.environment}-backend-tg"
  port        = 5000
  protocol    = "HTTP"
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
  security_groups    = [var.web_security_group_id]
  subnets            = var.public_subnet_ids
  
  tags = {
    Name        = "${var.environment}-web-alb"
    Environment = var.environment
  }
}

# ALB Listener (default to frontend)
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
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
