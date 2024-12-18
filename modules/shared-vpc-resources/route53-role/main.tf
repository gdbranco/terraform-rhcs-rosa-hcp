resource "aws_iam_role" "route53_role" {
  name                 = substr("${var.name_prefix}-shared-route53-role", 0, 64)
  permissions_boundary = var.permission_boundary
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "BeAssumableFrom"
        Principal = {
          AWS = [
            var.installer_role_arn,
            var.control_plane_role_arn,
            var.ingress_role_arn,
          ]
        }
      }
    ]
  })
  description = "Role that managed Route 53 and will be assumed from the Target AWS account where the cluster resides"
}

## Policy to be migrated to aws managed policy
data "http" "route53_perms" {
  url = "https://raw.githubusercontent.com/openshift/managed-cluster-config/refs/heads/master/resources/sts/4.17/hypershift/openshift_hcp_shared_vpc_route_53_credentials_policy.json"

  request_headers = {
    Accept = "application/json"
  }
}

resource "aws_iam_policy" "route53_policy" {
  name   = substr("${var.name_prefix}-shared-route53-policy", 0, 64)
  policy = data.http.route53_perms.response_body
}

resource "aws_iam_role_policy_attachment" "route53_role_policy_attachment" {
  role       = aws_iam_role.route53_role.name
  policy_arn = aws_iam_policy.route53_policy.arn
}

resource "time_sleep" "route53_role_propagation" {
  destroy_duration = "20s"
  create_duration  = "20s"

  triggers = {
    role_name  = aws_iam_role_policy_attachment.route53_role_policy_attachment.role
    role_arn   = aws_iam_role.route53_role.arn
    policy_arn = aws_iam_role_policy_attachment.route53_role_policy_attachment.policy_arn
  }
}
