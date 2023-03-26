resource "kubectl_manifest" "haproxy_service" {
  count     = var.environment != "dev" ? 1 : 0
  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: haproxy
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "TCP"
    service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "600"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-attributes: access_logs.s3.enabled=true,access_logs.s3.bucket=${data.terraform_remote_state.s3.outputs.alb_logs_s3_bucket},access_logs.s3.prefix=haproxy
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: "/stats"
spec:
  selector:
    app: haproxy
  ports:
    - name: https
      protocol: TCP
      port: 443
      targetPort: 443
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
YAML
}

resource "time_sleep" "wait_180_seconds" {
  depends_on       = [kubectl_manifest.haproxy_service]
  create_duration  = "180s"
  destroy_duration = "10s"
}

data "aws_lb" "haproxy" {
  depends_on = [time_sleep.wait_180_seconds]
  tags = {
    "kubernetes.io/service-name"                                                        = "default/haproxy"
    "kubernetes.io/cluster/${data.terraform_remote_state.vpc.outputs.eks_cluster_name}" = "owned"
  }
}


data "aws_lb" "haproxy_dr" {
  count      = var.environment == "prod" ? 1 : 0
  provider   = aws.us-west-2
  depends_on = [time_sleep.wait_180_seconds]
  tags = {
    "kubernetes.io/service-name" = "default/haproxy"
  }
}

resource "aws_globalaccelerator_accelerator" "aws_globalaccelerator_accelerator" {
  count           = var.environment == "prod" ? 1 : 0
  name            = "${var.environment}-ga"
  ip_address_type = "IPV4"
  enabled         = true
}

resource "aws_globalaccelerator_listener" "aws_globalaccelerator_listener" {
  count           = var.environment == "prod" ? 1 : 0
  accelerator_arn = aws_globalaccelerator_accelerator.aws_globalaccelerator_accelerator[0].id
  protocol        = "TCP"
  port_range {
    from_port = 443
    to_port   = 443
  }
  port_range {
    from_port = 80
    to_port   = 80
  }
}

resource "aws_globalaccelerator_endpoint_group" "aws_globalaccelerator_endpoint_group" {
  count                         = var.environment == "prod" ? 1 : 0
  depends_on                    = [data.aws_lb.haproxy, time_sleep.wait_180_seconds]
  listener_arn                  = aws_globalaccelerator_listener.aws_globalaccelerator_listener[0].id
  health_check_protocol         = "TCP"
  health_check_path             = "/stats"
  health_check_interval_seconds = 10
  threshold_count               = 1
  traffic_dial_percentage       = 50
  endpoint_configuration {
    endpoint_id = data.aws_lb.haproxy.arn
    weight      = 255
  }
}

resource "aws_globalaccelerator_endpoint_group" "aws_globalaccelerator_endpoint_group_dr" {
  count                         = var.environment == "prod" ? 1 : 0
  provider                      = aws.us-west-2
  depends_on                    = [data.aws_lb.haproxy, time_sleep.wait_180_seconds]
  listener_arn                  = aws_globalaccelerator_listener.aws_globalaccelerator_listener[0].id
  health_check_protocol         = "TCP"
  health_check_path             = "/stats"
  health_check_interval_seconds = 10
  threshold_count               = 1
  traffic_dial_percentage       = 50
  endpoint_configuration {
    endpoint_id = data.aws_lb.haproxy_dr[0].arn
    weight      = 255
  }
}
