# ============================================================
# VPC 모듈 출력값 정의
# 다른 모듈에서 참조할 수 있는 VPC 관련 정보 내보내기
# ============================================================

# VPC의 고유 ID 출력
# 다른 리소스(보안그룹, 서브넷 등)에서 VPC 참조시 사용
output "vpc_id" {
  value = aws_vpc.main.id
}

# 사용 중인 가용영역 목록 출력
# EC2 인스턴스 배치 등에서 가용영역 정보 필요시 사용
output "az-list" {
  value = local.az_list
}

# 모든 퍼블릭 서브넷의 ID 목록 출력
# EC2, 로드밸런서 등 퍼블릭 리소스 배치시 사용
# [*] 표현식: 리스트의 모든 요소에서 id 속성 추출 (Splat Expression)
output "public_subnet_ids" {
  value = aws_subnet.publics[*].id
  # 참고: map 타입이라면 for문 사용
  # [for key in aws_subnet.publics : aws_subnet.publics[key].id]
}

# 모든 프라이빗 서브넷의 ID 목록 출력
# RDS, 내부 서비스 등 프라이빗 리소스 배치시 사용
output "private_subnet_ids" {
  value = aws_subnet.privates[*].id
}