output "waf_arn" {
  description = "생성된 WAF Web ACL의 ARN입니다. ALB 연결에 사용됩니다."
  value       = aws_wafv2_web_acl.wp_waf.arn
}