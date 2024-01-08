# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_security_group" "alb_sg" {
  name        = "ApplicationLoadBalancerSecurityGroup"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "TLS from everywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "TLS to target Security Groups"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.target_security_group_ids
  }
}

##################################################################################
# TARGET GROUP
##################################################################################

# S3
resource "aws_lb_target_group" "s3" {
  name        = "AlbS3TargetGroup"
  target_type = "ip"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id

  health_check {
    matcher  = "200,403"
    protocol = "HTTPS"
  }
}

data "aws_vpc_endpoint" "s3_vpce" {
  id = var.s3_vpce_id
}

data "aws_network_interface" "s3_vpce_enis" {
  count = var.s3_vpce_nr_ips
  id    = flatten(data.aws_vpc_endpoint.s3_vpce.network_interface_ids)[count.index]
}

resource "aws_lb_target_group_attachment" "s3" {
  count            = var.s3_vpce_nr_ips
  target_group_arn = aws_lb_target_group.s3.arn
  target_id        = flatten(data.aws_network_interface.s3_vpce_enis[*].private_ips)[count.index]
}

# Execute API
resource "aws_lb_target_group" "execute_api" {
  count       = var.attach_api ? 1 : 0
  name        = "AlbExecuteApiTargetGroup"
  target_type = "ip"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id

  health_check {
    matcher  = "200,403"
    protocol = "HTTPS"
  }
}

data "aws_vpc_endpoint" "execute_api_vpce" {
  count = var.attach_api ? 1 : 0
  id    = var.execute_api_vpce_id
}

data "aws_network_interface" "execute_api_vpce_enis" {
  count = var.attach_api ? var.execute_api_vpce_nr_ips : 0
  id    = flatten(data.aws_vpc_endpoint.execute_api_vpce[0].network_interface_ids)[count.index]
}

resource "aws_lb_target_group_attachment" "execute_api" {
  count            = var.attach_api ? var.execute_api_vpce_nr_ips : 0
  target_group_arn = aws_lb_target_group.execute_api[0].arn
  target_id        = flatten(data.aws_network_interface.execute_api_vpce_enis[*].private_ips)[count.index]
}

# APPLICATION LOAD BALANCER
resource "aws_lb" "alb" {
  name = "AlbS3Vpce"

  load_balancer_type         = "application"
  subnets                    = var.subnet_ids
  security_groups            = [aws_security_group.alb_sg.id]
  internal                   = true
  enable_deletion_protection = true
}

# Default Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  certificate_arn = data.aws_acm_certificate.cert.arn

  default_action {
    type  = "forward"
    order = 50000

    target_group_arn = aws_lb_target_group.s3.arn
  }
}

# API Listener Rule
resource "aws_lb_listener_rule" "api_rule" {
  count        = var.attach_api ? 1 : 0
  listener_arn = aws_lb_listener.https.arn

  priority = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.execute_api[0].arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# Route 53
resource "aws_route53_record" "alb" {
  count   = var.hosted_zone_id != null ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}
