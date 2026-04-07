# ============================================================
# Launch Template 모듈
# 프로젝트 목적: Auto Scaling에서 사용할 EC2 인스턴스 템플릿 생성
# 학습 목표: Launch Template을 통한 인스턴스 설정 표준화
# ============================================================

# ------------------------------------------------------------
# EC2 Launch Template 리소스
# 역할: Auto Scaling에서 사용할 인스턴스 설정을 템플릿으로 정의
# 학습 포인트: for_each를 사용한 동적 리소스 생성
# ------------------------------------------------------------
resource "aws_launch_template" "templates" {
  # 템플릿 맵의 각 항목에 대해 시작 템플릿 생성
  for_each = var.templates

  # 템플릿 이름: AWS 콘솔에서 식별하는 이름
  name = each.value.name
  
  # 템플릿 설명: 용도 명시
  description = each.value.description
  
  # AMI ID: ami_name을 ami_images 맵에서 조회하여 실제 AMI ID 사용
  # 예: "project-mega" → "ami-009df9195e694eb80"
  image_id = var.ami_images[each.value.ami_name]
  
  # SSH 키 페어 이름: 인스턴스 접속용 SSH 키
  key_name = var.key_name
  
  # 네트워크 인터페이스 설정
  network_interfaces {
    # 퍼블릭 IP 할당 여부: true면 퍼블릭 IP, false면 프라이빗 IP만
    associate_public_ip_address = each.value.public
    
    # 적용할 보안 그룹 ID
    security_groups = [var.sg_ids[each.value.sg_name]]
  }
  
  # 태그: 인스턴스에 자동으로 적용되는 태그
  tags = {
    Name = "${var.region_name}-ec2-js-${each.key}"
  }
}
