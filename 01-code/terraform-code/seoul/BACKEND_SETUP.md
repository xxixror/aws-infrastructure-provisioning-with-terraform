# Terraform Remote State Backend 설정 가이드

협업을 위해 Terraform state를 S3에 저장하고 DynamoDB로 locking을 관리합니다.

## 설정 단계

### 1단계: Backend 리소스 생성 (S3 버킷, DynamoDB 테이블)

먼저 S3 버킷과 DynamoDB 테이블을 생성합니다:

```bash
cd seoul

# Backend 리소스만 생성
terraform apply
```

이 명령어로 다음이 생성됩니다:
- S3 버킷: `terraform-state-seoul-js-{계정ID}`
- DynamoDB 테이블: `terraform-state-lock-seoul-js`

### 2단계: Backend 설정 활성화

`seoul/main.tf` 파일에서 backend 설정 주석을 해제하고 수정:

```hcl
terraform {
  # ... 기존 설정 ...
  
  backend "s3" {
    bucket         = "terraform-state-seoul-js-{계정ID}"  # 실제 계정ID로 변경
    key            = "seoul/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-state-lock-seoul-js"
    encrypt        = true
  }
}
```

**계정ID 확인 방법:**
```bash
aws sts get-caller-identity --query Account --output text
```

### 3단계: State 마이그레이션

기존 로컬 state를 S3로 마이그레이션:

```bash
terraform init -migrate-state
```

확인 메시지가 나오면 `yes` 입력

### 4단계: 확인

```bash
# State가 S3에서 로드되는지 확인
terraform state list

# S3 버킷에 state 파일이 있는지 확인
aws s3 ls s3://terraform-state-seoul-js-{계정ID}/seoul/
```

## 협업 시 사용 방법

### 다른 팀원이 사용할 때

1. 코드 받기 (Git clone 등)
2. Backend 설정 확인 (`seoul/main.tf`의 backend 블록)
3. Terraform 초기화:
   ```bash
   cd seoul
   terraform init
   ```
4. State는 자동으로 S3에서 로드됨

### 주의사항

- **State Locking**: 한 사람이 `terraform apply`를 실행 중이면, 다른 사람은 대기해야 함
- **충돌 방지**: 항상 `terraform pull` 또는 최신 코드를 받은 후 작업
- **Backend 리소스 보호**: S3 버킷과 DynamoDB 테이블은 `prevent_destroy = true`로 설정되어 있어 실수로 삭제되지 않음

## 문제 해결

### State Lock이 해제되지 않을 때

```bash
# DynamoDB에서 lock 확인
aws dynamodb scan --table-name terraform-state-lock-seoul-js

# 필요시 수동으로 lock 제거 (주의: 다른 사람이 작업 중이 아닐 때만)
aws dynamodb delete-item \
  --table-name terraform-state-lock-seoul-js \
  --key '{"LockID":{"S":"<lock-id>"}}'
```

### State 파일 복구

S3 버킷의 버전 관리가 활성화되어 있으므로, 이전 버전으로 복구 가능:
```bash
aws s3api list-object-versions \
  --bucket terraform-state-seoul-js-{계정ID} \
  --prefix seoul/terraform.tfstate
```

