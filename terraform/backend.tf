# ── Application Load Balancer ──
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name    = "${var.project_name}-alb"
    Project = var.project_name
  }
}

# ── Target Group ──
resource "aws_lb_target_group" "backend" {
  name     = "${var.project_name}-tg-backend"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name    = "${var.project_name}-tg-backend"
    Project = var.project_name
  }
}

# ── Listener ──
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# ── Launch Template ──
resource "aws_launch_template" "backend" {
  name_prefix   = "${var.project_name}-backend-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.backend.id]
  }

  user_data = base64encode(templatefile("user_data_backend.sh", {
    db_host     = aws_db_instance.main.address
    db_name     = var.db_name
    db_username = var.db_username
    db_password = var.db_password
    github_repo = var.github_repo
    app_port    = var.app_port
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project_name}-backend"
      Project = var.project_name
    }
  }
}

# ── Auto Scaling Group ──
resource "aws_autoscaling_group" "backend" {
  name                = "${var.project_name}-asg"
  desired_capacity    = 2
  min_size            = 1
  max_size            = 4
  vpc_zone_identifier = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  target_group_arns   = [aws_lb_target_group.backend.arn]

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.project_name}-backend"
    propagate_at_launch = true
  }
}

# ── Scaling Policy ──
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.project_name}-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.backend.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# ── Stocker l'URL ALB dans Parameter Store ──
resource "aws_ssm_parameter" "alb_url" {
  name  = "/${var.project_name}/alb-url"
  type  = "String"
  value = aws_lb.main.dns_name

  tags = {
    Name    = "${var.project_name}-alb-url"
    Project = var.project_name
  }
}