# Target Group for ALB
resource "aws_lb_target_group" "web" {
  name     = "${var.environment}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
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

# Attachment of ASG to Target Group
resource "aws_autoscaling_attachment" "web" {
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

# ALB Listener
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
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
