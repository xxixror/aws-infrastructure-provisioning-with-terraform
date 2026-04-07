# ============================================================
# EC2 모듈
# 프로젝트 목적: AWS 가상 서버 인스턴스 생성 (웹, DB, DNS 등)
# 학습 목표: Terraform의 for_each와 merge를 활용한 동적 리소스 생성
# ============================================================

# ------------------------------------------------------------
# EC2 인스턴스 맵 생성 (로컬 변수)
# 역할: 입력된 인스턴스 설정을 평면화하여 for_each에서 사용할 맵 생성
# 학습 포인트: 중첩 구조를 평면화하는 Terraform 고급 기법
# ------------------------------------------------------------
locals {
  # merge()와 for 표현식을 사용하여 중첩 구조를 평면화
  # 예: { web: {count:2} } → { "web-1": {...}, "web-2": {...} }
  ec2_map = merge([
    # 각 인스턴스 유형(k)과 설정(v)에 대해 반복
    for k, v in var.ec2-instances : {
      # count 수만큼 개별 인스턴스 항목 생성
      for i in range(v.count) : "${k}-${i + 1}" => merge(v, {
        # public 여부에 따라 적절한 서브넷 할당 (라운드 로빈 방식)
        # public=true면 퍼블릭 서브넷, false면 프라이빗 서브넷
        # i % length(...)로 서브넷을 순환 배치하여 부하 분산
        subnet_id = v.public ? var.public_subnet_ids[i % length(var.public_subnet_ids)] : var.private_subnet_ids[i % length(var.private_subnet_ids)]
      })
    }
  ]...)  # ... 연산자: 리스트를 개별 인자로 펼침 (merge에 전달)
}

# ------------------------------------------------------------
# EC2 인스턴스 생성 (for_each 사용)
# 역할: 위에서 생성한 맵을 기반으로 인스턴스 동적 생성
# 학습 포인트: for_each를 사용한 동적 리소스 생성
# ------------------------------------------------------------
resource "aws_instance" "ec2s" {
  # 로컬 맵의 각 항목에 대해 인스턴스 생성
  for_each = local.ec2_map
  
  # AMI (Amazon Machine Image): 인스턴스의 운영체제 이미지
  ami = each.value.ami
  
  # 인스턴스 타입: CPU, 메모리 등 하드웨어 사양
  instance_type = each.value.instance_type
  
  # 서브넷 ID: 인스턴스가 배치될 서브넷
  subnet_id = each.value.subnet_id
  
  # 보안 그룹: 인스턴스에 적용할 방화벽 규칙
  security_groups = [var.sg_ids[each.value.sg_name]]
  
  # SSH 키 페어: 인스턴스 접속용 SSH 키 이름
  key_name = var.key_name
  
  # User Data: 인스턴스 최초 부팅 시 실행할 스크립트
  # 예: 웹 서버 설치, 애플리케이션 설정 등
  user_data = each.value.user_data
  
  tags = {
    # 인스턴스 이름: {리전}-Ec2-js-{용도}-{번호}
    Name = "${var.region_name}-ec2-js-${each.key}"
  }
}
