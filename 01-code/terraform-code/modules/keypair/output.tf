# ============================================================
# Keypair 모듈 출력값 정의
# 생성된 키 정보를 다른 모듈에서 사용할 수 있도록 내보냄
# ============================================================

# 비밀키 출력 (PEM 형식, OpenSSH 호환)
# 주의: 민감 정보이므로 안전하게 저장해야 함
# 로컬 파일로 저장 후 SSH 접속 시 사용: ssh -i <private_key_file> ec2-user@<ip>
output "private_key" {
  description = "SSH 비밀키 (OpenSSH 형식)"
  value       = tls_private_key.generate.private_key_openssh
  sensitive   = true  # 콘솔 출력 시 마스킹 (선택 사항)
}

# 공개키 출력 (OpenSSH 형식)
# authorized_keys에 추가되는 형식
output "public_key" {
  description = "SSH 공개키 (OpenSSH 형식)"
  value       = tls_private_key.generate.public_key_openssh
}

# AWS에 등록된 키 페어 이름 출력
# EC2 인스턴스 생성 시 key_name 파라미터에 전달
output "key_name" {
  description = "AWS에 등록된 키 페어 이름"
  value       = aws_key_pair.aws.key_name
}
