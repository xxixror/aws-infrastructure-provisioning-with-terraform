# ============================================================
# RDS 모듈
# 프로젝트 목적: MariaDB 데이터베이스 인스턴스 생성 (WordPress용)
# 학습 목표: RDS를 통한 관리형 데이터베이스 서비스 이해
# ============================================================

# ------------------------------------------------------------
# DB 서브넷 그룹 리소스
# 역할: RDS 인스턴스를 배치할 서브넷 그룹 정의
# 학습 포인트: RDS는 여러 가용영역의 서브넷에 배치 가능 (고가용성)
# ------------------------------------------------------------
resource "aws_db_subnet_group" "db" {
  name        = var.rds_subnet_group.name
  description = var.rds_subnet_group.description
  # 프라이빗 서브넷 ID 목록: 보안을 위해 프라이빗 서브넷에 배치
  subnet_ids  = var.subnet_ids
}

# ------------------------------------------------------------
# RDS 인스턴스 리소스
# 역할: MariaDB 데이터베이스 인스턴스 생성
# 학습 포인트: 관리형 데이터베이스의 장점 (백업, 패치, 모니터링 자동화)
# ------------------------------------------------------------
resource "aws_db_instance" "db-instance" {
  # DB 서브넷 그룹이 먼저 생성되어야 함
  depends_on = [aws_db_subnet_group.db]
  
  # 데이터베이스 엔진 설정
  engine         = var.db_instance.engine         # "mariadb"
  engine_version = var.db_instance.engine_version # "11.4.5"
  identifier     = var.db_instance.identifier     # DB 인스턴스 식별자
  
  # 인증 정보
  username = var.db_instance.username
  password = var.db_instance.password  # 환경변수에서 설정 (보안)

  # 인스턴스 사양
  instance_class    = var.db_instance.instance_class    # "db.t4g.micro"
  storage_type      = var.db_instance.storage_type      # "gp3" (SSD)
  allocated_storage = var.db_instance.allocated_storage # 20 GB
  multi_az          = var.db_instance.multi_az          # 다중 가용영역 배치 여부

  # 네트워크 및 보안 설정
  db_subnet_group_name   = aws_db_subnet_group.db.name
  # 보안 그룹 ID 목록: 여러 보안 그룹 적용 가능
  vpc_security_group_ids = [for name in var.db_instance.sg_names : var.sg_ids[name]]
  # 공개 접근 가능 여부: false = 프라이빗 서브넷에서만 접근 가능
  publicly_accessible    = var.db_instance.publicly_accessible

  # 스냅샷 설정: 스냅샷에서 복원할 경우
  # snapshot_identifier가 지정되어 있으면 해당 스냅샷에서 복원
  snapshot_identifier = var.db_instance.snapshot_identifier != "" ? var.db_instance.snapshot_identifier : null

  # 백업 및 삭제 설정
  skip_final_snapshot       = true   # 삭제 시 최종 스냅샷 생성 안 함
  deletion_protection       = false  # 삭제 보호 비활성화
  # 최종 스냅샷 식별자 (생명주기에서 무시)
  final_snapshot_identifier = "${var.db_instance.identifier}-${replace(timestamp(), ":", "-")}"

  # 생명주기 규칙: final_snapshot_identifier 변경 무시
  # timestamp()는 매번 다른 값을 반환하므로 변경 무시 필요
  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}
