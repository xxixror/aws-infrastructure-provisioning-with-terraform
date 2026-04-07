# ============================================================
# Target Group 모듈 출력값 정의
# 생성된 타겟 그룹 정보를 다른 모듈에서 참조할 수 있도록 내보냄
# ============================================================

# 타겟 그룹 ARN 출력
# 로드밸런서 리스너 및 Auto Scaling 그룹에서 참조
# ARN (Amazon Resource Name): AWS 리소스의 고유 식별자
output "target_group_arn" {
  description = "타겟 그룹의 ARN (로드밸런서 연결에 사용)"
  value       = aws_lb_target_group.name.arn
}
