# EC2 인스턴스 개수 동적 설정 가이드

## 개요

EC2 인스턴스 개수를 `terraform apply` 실행 시 동적으로 입력받아 설정할 수 있습니다.

## 사용 방법

### 방법 1: terraform.tfvars 파일 사용 (권장)

1. `terraform.tfvars.example` 파일을 `terraform.tfvars`로 복사:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. `terraform.tfvars` 파일을 편집하여 원하는 개수 설정:
```hcl
ec2_instance_counts = {
  web = 2  # 웹 서버 2개
  db  = 1  # 데이터베이스 서버 1개
  dns = 0  # DNS 서버 생성 안함
}
```

3. Terraform 실행:
```bash
terraform apply
```

### 방법 2: 명령줄에서 직접 입력

```bash
# 웹 서버 2개만 생성
terraform apply -var='ec2_instance_counts={web=2}'

# 여러 인스턴스 동시 설정
terraform apply -var='ec2_instance_counts={web=2,db=1}'
```

### 방법 3: 대화형 입력

변수를 설정하지 않으면 Terraform이 대화형으로 입력을 요청합니다:

```bash
terraform apply
# Enter a value: {web=2,db=1}
```

## 설정 예시

### 예시 1: 웹 서버만 2개 생성
```hcl
ec2_instance_counts = {
  web = 2
}
```

### 예시 2: 모든 인스턴스 생성 안함 (기본값)
```hcl
# terraform.tfvars 파일을 만들지 않거나
# ec2_instance_counts를 설정하지 않으면
# variables.yml의 기본값(0) 사용
```

### 예시 3: 모든 인스턴스 생성
```hcl
ec2_instance_counts = {
  web = 2
  db  = 1
  dns = 1
}
```

## 주의사항

- `variables.yml`의 기본값은 `count: 0`으로 설정되어 있습니다
- Terraform 변수로 개수를 지정하지 않으면 인스턴스가 생성되지 않습니다
- 설정한 개수만큼 인스턴스가 생성됩니다
- 기존 인스턴스가 있는 경우, 개수를 줄이면 해당 인스턴스가 삭제될 수 있습니다



