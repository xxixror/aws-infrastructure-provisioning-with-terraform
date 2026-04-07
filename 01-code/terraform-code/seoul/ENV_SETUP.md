# 환경변수 설정 가이드

이 프로젝트는 보안을 위해 비밀번호를 환경변수로 관리합니다.

## 필요한 환경변수

- `RDS_PASSWORD`: RDS 데이터베이스 인스턴스 비밀번호
- `WORDPRESS_DB_PASSWORD`: WordPress 데이터베이스 연결 비밀번호

## 설정 방법

### 방법 1: 직접 환경변수 설정

#### Windows PowerShell
```powershell
$env:RDS_PASSWORD = "your-rds-password"
$env:WORDPRESS_DB_PASSWORD = "your-wordpress-db-password"
```

#### Windows CMD
```cmd
set RDS_PASSWORD=your-rds-password
set WORDPRESS_DB_PASSWORD=your-wordpress-db-password
```

#### Linux/Mac (Bash/Zsh)
```bash
export RDS_PASSWORD="your-rds-password"
export WORDPRESS_DB_PASSWORD="your-wordpress-db-password"
```

### 방법 2: .env 파일 사용 (권장)

1. `.env.example` 파일을 복사하여 `.env` 파일 생성:
   ```bash
   cp .env.example .env
   ```

2. `.env` 파일을 열어 실제 비밀번호로 변경

3. 환경변수로 로드:

   **Windows PowerShell:**
   ```powershell
   Get-Content .env | ForEach-Object {
     if ($_ -match '^([^=]+)=(.*)$') {
       [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
     }
   }
   ```

   **Linux/Mac:**
   ```bash
   source .env
   # 또는
   export $(cat .env | xargs)
   ```

### 방법 3: Terraform 변수로 직접 전달

환경변수 대신 `terraform apply` 시 직접 전달:

```bash
terraform apply \
  -var='rds_password=your-rds-password' \
  -var='wordpress_db_password=your-wordpress-db-password'
```

또는 `terraform.tfvars` 파일 사용:

```hcl
rds_password           = "your-rds-password"
wordpress_db_password  = "your-wordpress-db-password"
```

```bash
terraform apply -var-file="terraform.tfvars"
```

## 보안 주의사항

⚠️ **중요**: 
- `.env` 파일은 절대 Git에 커밋하지 마세요!
- `.gitignore`에 `.env` 파일이 포함되어 있는지 확인하세요
- 비밀번호는 강력한 것으로 설정하세요 (최소 12자 이상, 대소문자/숫자/특수문자 포함)

## 확인 방법

환경변수가 제대로 설정되었는지 확인:

**Windows PowerShell:**
```powershell
echo $env:RDS_PASSWORD
echo $env:WORDPRESS_DB_PASSWORD
```

**Linux/Mac:**
```bash
echo $RDS_PASSWORD
echo $WORDPRESS_DB_PASSWORD
```

## Terraform 실행

환경변수 설정 후:

```bash
cd seoul
terraform init
terraform plan   # 변경사항 확인
terraform apply  # 인프라 배포
```

환경변수가 설정되지 않으면 Terraform이 에러를 발생시킵니다.


