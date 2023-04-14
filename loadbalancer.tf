# Create a security group for the load balancer to access the web application
data "aws_acm_certificate" "example_cert" {
  domain   = var.prod_domain
  statuses = ["ISSUED"]
}

resource "aws_security_group" "load_balancer_security_group" {
  name_prefix = "load_balancer_sg_"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# # Update the EC2 security group for your EC2 instances that will host web applications
# resource "aws_security_group_rule" "web_app_ingress_rule" {
#   type        = "ingress"
#   from_port   = 22
#   to_port     = 22
#   protocol    = "tcp"
#   security_group_id = aws_security_group.web_app_security_group.id
#   source_security_group_id = aws_security_group.load_balancer_security_group.id
# }

# resource "aws_security_group_rule" "app_port_ingress_rule" {
#   type        = "ingress"
#   from_port   = var.app_port
#   to_port     = var.app_port
#   protocol    = "tcp"
#   security_group_id = aws_security_group.web_app_security_group.id
#   source_security_group_id = aws_security_group.load_balancer_security_group.id
# }

#Setup Autoscaling for EC2 Instances
# resource "aws_launch_configuration" "asg_launch_config" {
#   image_id                    = var.latest_ami
#   instance_type               = "t2.micro"
#   key_name                    = aws_key_pair.example.key_name
#   associate_public_ip_address = true
#   iam_instance_profile        = aws_iam_instance_profile.s3_access_instance_profile.name
#   user_data                   = <<EOT
# #!/bin/bash
# cat <<EOF > /etc/systemd/system/webapp.service
# [Unit]
# Description=Webapp Service
# After=network.target

# [Service]
# Environment="NODE_ENV=dev"
# Environment="DB_PORT=3306"
# Environment="DB_DIALECT=mysql"
# Environment="DB_HOST=${element(split(":", aws_db_instance.rds_instance.endpoint), 0)}"
# Environment="DB_USER=${aws_db_instance.rds_instance.username}"
# Environment="DB_PASSWORD=${aws_db_instance.rds_instance.password}"
# Environment="DB=${aws_db_instance.rds_instance.db_name}"
# Environment="AWS_BUCKET_NAME=${aws_s3_bucket.webapp-s3.bucket}"
# Environment="AWS_REGION=${var.aws_region}"

# Type=simple
# User=ec2-user
# WorkingDirectory=/home/ec2-user/webapp
# ExecStart=/usr/bin/node listener.js
# Restart=on-failure

# [Install]
# WantedBy=multi-user.target" > /etc/systemd/system/webapp.service
# EOF


# sudo systemctl daemon-reload
# sudo systemctl start webapp.service
# sudo systemctl enable webapp.service
# sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/tmp/config.json
# echo 'export NODE_ENV=dev' >> /home/ec2-user/.bashrc,
# echo 'export PORT=3000' >> /home/ec2-user/.bashrc,
# echo 'export DB_DIALECT=mysql' >> /home/ec2-user/.bashrc,
# echo 'export DB_HOST=${element(split(":", aws_db_instance.rds_instance.endpoint), 0)}' >> /home/ec2-user/.bashrc,
# echo 'export DB_USERNAME=${aws_db_instance.rds_instance.username}' >> /home/ec2-user/.bashrc,
# echo 'export DB_PASSWORD=${aws_db_instance.rds_instance.password}' >> /home/ec2-user/.bashrc,
# echo 'export DB_NAME=${aws_db_instance.rds_instance.db_name}' >> /home/ec2-user/.bashrc,
# echo 'export AWS_BUCKET_NAME=${aws_s3_bucket.webapp-s3.bucket}' >> /home/ec2-user/.bashrc,
# echo 'export AWS_REGION=${var.aws_region}' >> /home/ec2-user/.bashrc,
# source /home/ec2-user/.bashrc
# EOT

#   security_groups = [aws_security_group.application.id]
#   root_block_device {
#     volume_size           = 50
#     volume_type           = "gp2"
#     delete_on_termination = true
#   }
# }
resource "aws_launch_template" "asg_launch_template" {
  name = "asg-launch-template"
   network_interfaces {
    associate_public_ip_address = true
    security_groups      = [aws_security_group.application.id]
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 50
      volume_type = "gp2"
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.ebs_encryption_key.arn
    }
    
  }
  lifecycle {
    create_before_destroy = true
  }

  image_id = var.latest_ami
  instance_type = "t2.micro"
  key_name = aws_key_pair.example.key_name
  user_data =base64encode( <<-EOF
    #!/bin/bash
    cat <<EOT > /etc/systemd/system/webapp.service
    [Unit]
    Description=Webapp Service
    After=network.target
    
    [Service]
    Environment="NODE_ENV=dev"
    Environment="DB_PORT=3306"
    Environment="DB_DIALECT=mysql"
    Environment="DB_HOST=${element(split(":", aws_db_instance.rds_instance.endpoint), 0)}"
    Environment="DB_USER=${aws_db_instance.rds_instance.username}"
    Environment="DB_PASSWORD=${aws_db_instance.rds_instance.password}"
    Environment="DB=${aws_db_instance.rds_instance.db_name}"
    Environment="AWS_BUCKET_NAME=${aws_s3_bucket.webapp-s3.bucket}"
    Environment="AWS_REGION=${var.aws_region}"
    
    Type=simple
    User=ec2-user
    WorkingDirectory=/home/ec2-user/webapp
    ExecStart=/usr/bin/node listener.js
    Restart=on-failure
    
    [Install]
    WantedBy=multi-user.target
    EOT
    
    sudo systemctl daemon-reload
    sudo systemctl start webapp.service
    sudo systemctl enable webapp.service
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/tmp/config.json
    echo 'export NODE_ENV=dev' >> /home/ec2-user/.bashrc
    echo 'export PORT=3000' >> /home/ec2-user/.bashrc
    echo 'export DB_DIALECT=mysql' >> /home/ec2-user/.bashrc
    echo 'export DB_HOST=${element(split(":", aws_db_instance.rds_instance.endpoint), 0)}' >> /home/ec2-user/.bashrc
    echo 'export DB_USERNAME=${aws_db_instance.rds_instance.username}' >> /home/ec2-user/.bashrc
    echo 'export DB_PASSWORD=${aws_db_instance.rds_instance.password}' >> /home/ec2-user/.bashrc
    echo 'export DB_NAME=${aws_db_instance.rds_instance.db_name}' >> /home/ec2-user/.bashrc
    echo 'export AWS_BUCKET_NAME=${aws_s3_bucket.webapp-s3.bucket}' >> /home/ec2-user/.bashrc
    echo 'export AWS_REGION=${var.aws_region}' >> /home/ec2-user/.bashrc
    source /home/ec2-user/.bashrc
    EOF
  )
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "webapp-instance"
    }
  }
  
  # vpc_security_group_ids = [aws_security_group.application.id]
  
  iam_instance_profile {
    name = aws_iam_instance_profile.s3_access_instance_profile.name
  }
}

resource "aws_autoscaling_group" "web_app_asg" {
  name                 = "web_app_asg"
  health_check_grace_period = 1200
   launch_template {
    id      = aws_launch_template.asg_launch_template.id
    version = "$Latest"
   }
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  vpc_zone_identifier = [aws_subnet.public_subnets[0].id,
    aws_subnet.public_subnets[1].id,
  aws_subnet.public_subnets[2].id]
  health_check_type = "EC2"
  target_group_arns = [aws_lb_target_group.web_http.arn]


  lifecycle {
    create_before_destroy = true
  }
 

}

resource "aws_autoscaling_policy" "scale_up_policy" {
  name                    = "scale_up_policy"
  policy_type             = "SimpleScaling"
  adjustment_type         = "ChangeInCapacity"
  autoscaling_group_name  = aws_autoscaling_group.web_app_asg.name
  scaling_adjustment      = 1
  cooldown                = 60
  metric_aggregation_type = "Average"


}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                    = "scale_down_policy"
  policy_type             = "SimpleScaling"
  adjustment_type         = "ChangeInCapacity"
  autoscaling_group_name  = aws_autoscaling_group.web_app_asg.name
  scaling_adjustment      = -1
  cooldown                = 60
  metric_aggregation_type = "Average"


}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale_up_alarm"
  alarm_description   = "scale_up_alarm"
  evaluation_periods  = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  treat_missing_data  = "notBreaching"
  statistic           = "Average"
  threshold           = "5"
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.web_app_asg.name}"
  }
  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.scale_up_policy.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "scale_down_alarm"
  alarm_description   = "scaledownalarm"
  evaluation_periods  = "2"
  comparison_operator = "LessThanOrEqualToThreshold"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "2"
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.web_app_asg.name}"
  }
  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.scale_down_policy.arn}"]
}
resource "aws_lb" "web" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_security_group.id]
  subnets = [
    aws_subnet.public_subnets[0].id,
    aws_subnet.public_subnets[1].id,
    aws_subnet.public_subnets[2].id
  ]

  tags = {
    Name = "web-alb"
  }
}

resource "aws_lb_listener" "web_http" {
  load_balancer_arn = aws_lb.web.arn
  port              = "443"
  protocol          = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_http.arn
  }
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = "${data.aws_acm_certificate.example_cert.arn}"
}

resource "aws_lb_target_group" "web_http" {
  name_prefix = "weblbt"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    path                = "/healthz"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 20
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name = "web-http-tg"
  }
}
resource "aws_kms_key" "ebs_encryption_key" {
  description             = "Customer managed key for EBS encryption"
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow access for Key Administrators"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        Resource = "*"
      },
      {
        Sid    = "Enable EBS Encryption"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_key" "rds_encryption_key" {
  description             = "Customer managed key for EBS encryption"
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow access for Key Administrators"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        Resource = "*"
      },
      {
        Sid    = "Enable EBS Encryption"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}