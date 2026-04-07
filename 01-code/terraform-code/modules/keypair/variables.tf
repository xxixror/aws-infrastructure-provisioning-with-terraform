# ============================================================
# Keypair 모듈 입력 변수 정의
# SSH 키 생성에 필요한 변수들
# ============================================================

# 리전 식별 이름 (키 페어 이름에 사용)
variable "region_name" {
  description = "AWS 리전 이름 (키 페어 명명에 사용)"
  type        = string
}

# 키 생성 정보 객체
variable "key_info" {
  description = "SSH 키 생성을 위한 설정 정보"
  type = object({
    # 암호화 알고리즘: RSA, ECDSA, ED25519
    algorithm = string
    
    # RSA 키 비트수 (RSA 알고리즘 사용시에만 적용)
    # optional(): 선택적 속성으로, 기본값 2048 사용
    rsa_bits = optional(number, 2048)
  })
}
