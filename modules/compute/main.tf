# Web Tier Launch Template
resource "aws_launch_template" "web" {
  name_prefix   = "${var.environment}-web-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  
  vpc_security_group_ids = [var.web_security_group_id]
  
  user_data = base64encode(file("${path.module}/scripts/user.sh"))
  
  tag_specifications {
    resource_type = "instance"
    
    tags = {
      Name        = "${var.environment}-web-instance"
      Environment = var.environment
      Tier        = "web"
    }
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# App Tier Launch Template
resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-app-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  
  vpc_security_group_ids = [var.app_security_group_id]
  
  tag_specifications {
    resource_type = "instance"
    
    tags = {
      Name        = "${var.environment}-app-instance"
      Environment = var.environment
      Tier        = "app"
    }
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Web Tier Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                = "${var.environment}-web-asg"
  min_size            = var.web_min_size
  max_size            = var.web_max_size
  desired_capacity    = var.web_desired_capacity
  vpc_zone_identifier = var.public_subnet_ids
  health_check_type   = "EC2"
  termination_policies = ["OldestInstance"]
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "${var.environment}-web-asg"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# App Tier Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                = "${var.environment}-app-asg"
  min_size            = var.app_min_size
  max_size            = var.app_max_size
  desired_capacity    = var.app_desired_capacity
  vpc_zone_identifier = var.app_subnet_ids
  health_check_type   = "EC2"
  termination_policies = ["OldestInstance"]
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "${var.environment}-app-asg"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# Web Tier Auto Scaling Policy
resource "aws_autoscaling_policy" "web_cpu" {
  name                   = "${var.environment}-web-cpu-policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.web.name
  
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_threshold
  }
}

# App Tier Auto Scaling Policy
resource "aws_autoscaling_policy" "app_cpu" {
  name                   = "${var.environment}-app-cpu-policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.app.name
  
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_threshold
  }
}