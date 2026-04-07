# ============================================================
# Launch Template 모듈 출력값 정의
# 생성된 시작 템플릿 정보를 다른 모듈에서 참조할 수 있도록 내보냄
# ============================================================

# 시작 템플릿 ID 맵 출력
# 키: 템플릿 이름(each.key), 값: 템플릿 ID
# Auto Scaling 모듈에서 템플릿 ID 조회 시 사용
output "lt_ids" {
  description = "시작 템플릿 이름을 키로 하는 템플릿 ID 맵"
  value = {
    # for 표현식으로 맵 생성: {템플릿이름: 템플릿ID}
    for k, v in aws_launch_template.templates : k => v.id
  }
}
