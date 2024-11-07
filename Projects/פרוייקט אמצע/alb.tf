resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet[0].id, aws_subnet.public_subnet[1].id]
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "load baluncer security group"
  vpc_id      = aws_vpc.project-vpc.id

  tags = {
    Name = "alb_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_traffic_alb" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_server_rule" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol = "tcp"
  from_port = "80"
  to_port = "80"
  referenced_security_group_id = aws_security_group.server_sg.id
}

resource "aws_vpc_security_group_egress_rule" "alb_to_prom_rule" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol = "tcp"
  from_port = "9090"
  to_port = "9090"
  referenced_security_group_id = aws_security_group.server_sg.id
}

resource "aws_vpc_security_group_egress_rule" "alb_to_grafana_rule" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol = "tcp"
  from_port = "3000"
  to_port = "3000"
  referenced_security_group_id = aws_security_group.server_sg.id
}

resource "aws_vpc_security_group_egress_rule" "alb_to_loki_rule" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol = "tcp"
  from_port = "3100"
  to_port = "3100"
  referenced_security_group_id = aws_security_group.server_sg.id
}

resource "aws_lb_target_group" "application_tg" {
  name       = "application-target-group"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = aws_vpc.project-vpc.id
  depends_on = [aws_instance.Stock_Predict_Server]
}

resource "aws_lb_target_group_attachment" "application_tg_attachment" {
  target_group_arn = aws_lb_target_group.application_tg.arn
  target_id        = aws_instance.Stock_Predict_Server[0].id
  port             = 80
  depends_on       = [aws_lb_target_group.application_tg]
}

resource "aws_lb_target_group_attachment" "application1_tg_attachment" {
  target_group_arn = aws_lb_target_group.application_tg.arn
  target_id        = aws_instance.Stock_Predict_Server[1].id
  port             = 80
  depends_on       = [aws_lb_target_group.application_tg]
}

resource "aws_lb_listener" "my_alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  depends_on        = [aws_lb_target_group.application_tg]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application_tg.arn
  }
}
