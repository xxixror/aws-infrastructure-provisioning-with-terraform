# ============================================================
# Route53 모듈 - DNS 레코드 관리
# 로드밸런서 DNS를 사용자 정의 도메인에 연결하는 CNAME 레코드 생성
# ============================================================

# ------------------------------------------------------------
# Route53 DNS 레코드 생성
# for_each를 사용하여 여러 CNAME 레코드를 동적으로 생성
# ------------------------------------------------------------
resource "aws_route53_record" "records" {
  for_each = var.records
  
  # 호스팅 영역 ID: Route53에서 관리하는 도메인 영역의 고유 ID
  zone_id = each.value.zone_id
  
  # 레코드 이름: 사용자가 접속할 도메인 주소
  # 예: www.js.it-edu.org, database.js.it-edu.org
  name = each.value.name
  
  # 레코드 유형: CNAME(별칭 레코드)
  # CNAME: 한 도메인을 다른 도메인으로 매핑
  type = "CNAME"
  
  # 레코드 값: target_type에 따라 로드밸런서 또는 RDS 엔드포인트 선택
  # "lb" -> 로드밸런서 DNS 이름
  # "rds" -> RDS 엔드포인트 주소
  records = [each.value.target_type == "rds" ? var.rds_endpoint : var.lb_dns_name]
  
  # TTL (Time To Live): DNS 캐시 유지 시간(초)
  # 각 레코드별로 개별 설정 가능
  ttl = each.value.ttl
}
