# ============================================================
# Keypair 모듈 - SSH 키 페어 생성
# EC2 인스턴스에 SSH 접속하기 위한 공개키/비밀키 쌍을 생성합니다.
# ============================================================

# ------------------------------------------------------------
# TLS 비밀키 생성
# 로컬에서 RSA 또는 ECDSA 비밀키를 생성
# ------------------------------------------------------------
resource "tls_private_key" "generate" {
  # 암호화 알고리즘 (RSA, ECDSA, ED25519 등)
  algorithm = var.key_info.algorithm
  
  # RSA 키 비트 수 (2048, 4096 등 - RSA 알고리즘 사용시에만 적용)
  # 2048비트: 표준 보안 수준, 4096비트: 높은 보안 수준
  rsa_bits = var.key_info.rsa_bits
}

# ------------------------------------------------------------
# AWS 키 페어 등록
# 생성된 공개키를 AWS에 등록하여 EC2 인스턴스에서 사용 가능하게 함
# ------------------------------------------------------------
resource "aws_key_pair" "aws" {
  # OpenSSH 형식의 공개키 등록
  public_key = tls_private_key.generate.public_key_openssh
  
  # AWS에 등록될 키 페어 이름: {리전}-{알고리즘}-key
  # 예: seoul-rsa-key
  key_name = "${var.region_name}-${lower(var.key_info.algorithm)}-key-js"
}
