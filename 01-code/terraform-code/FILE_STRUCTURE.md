# 📁 파일 구조 및 용도 설명

## 프로젝트 루트

### 필수 파일
- **README.md** - 프로젝트 전체 설명 및 사용 가이드
- **FILE_STRUCTURE.md** - 이 파일 (파일 구조 설명)

### 참고 파일
- **memo.txt** - 개발 중 메모 (참고용, 삭제 가능)

---

## seoul/ 디렉토리 (서울 리전 인프라)

### 핵심 구성 파일
- **main.tf** ⭐
  - 모든 모듈을 조합하는 메인 구성 파일
  - Terraform Provider 설정
  - 모듈 호출 및 리소스 생성 순서 정의

- **variables.tf**
  - Terraform 명령줄에서 사용할 변수 정의
  - 현재는 `ec2_instance_counts`만 정의 (동적 인스턴스 개수 설정용)

- **variables.yml** ⭐
  - 인프라 전체 설정 파일 (YAML 형식)
  - VPC, Security Group, RDS, WAF 등 모든 설정 포함
  - **가장 중요한 설정 파일**

### 예시 및 문서
- **terraform.tfvars.example**
  - Terraform 변수 파일 예시
  - `terraform.tfvars`로 복사하여 사용

- **README_EC2.md**
  - EC2 인스턴스 개수 동적 설정 가이드


### Terraform 상태 파일 (자동 생성, Git 제외)
- **terraform.tfstate** - 현재 Terraform 상태
- **terraform.tfstate.backup** - 이전 상태 백업
- **id_rsa**, **id_rsa.pub** - SSH 키 파일 (자동 생성)

---

## modules/ 디렉토리 (재사용 가능한 모듈)

각 모듈은 독립적으로 사용 가능하며, 표준 구조를 따릅니다:
- **main.tf** - 리소스 정의
- **variables.tf** - 입력 변수
- **output.tf** - 출력 값

### 네트워크 모듈
- **vpc/** - VPC, 서브넷, 라우팅 테이블, 인터넷 게이트웨이

### 보안 모듈
- **security-group/** - 보안 그룹 (방화벽 규칙)
- **keypair/** - SSH 키 페어 생성
- **waf/** - Web Application Firewall
  - main.tf - WAF Web ACL 및 규칙
  - logging.tf - CloudWatch Logs 로깅 설정
  - alarms.tf - CloudWatch Alarms 설정

### 컴퓨팅 모듈
- **launch_template/** - EC2 시작 템플릿
- **ec2/** - EC2 인스턴스 (현재 사용 안 함, Launch Template 사용)
- **auto-scaling/** - Auto Scaling Group

### 로드밸런싱 모듈
- **target-group/** - 로드밸런서 대상 그룹
- **load-balancer/** - Application Load Balancer

### 데이터베이스 모듈
- **rds/** - RDS MariaDB 인스턴스

### DNS 모듈
- **route53/** - Route53 DNS 레코드

---

## 파일 분류

### ✅ 필수 파일 (삭제 금지)
- seoul/main.tf
- seoul/variables.yml
- seoul/variables.tf
- modules/*/main.tf
- modules/*/variables.tf
- modules/*/output.tf

### 📝 설정 파일 (수정 가능)
- seoul/variables.yml - 모든 인프라 설정
- seoul/terraform.tfvars.example - 변수 파일 예시

### 🔒 민감 정보 파일 (Git 제외)
- *.tfstate, *.tfstate.*
- id_rsa*, *.ppk
- wp-config.php
- *.tfvars

### 🗑️ 삭제 가능한 파일
- memo.txt - 개발 메모 (보관해도 됨)

### 📦 자동 생성 파일 (Git 제외)
- .terraform/ - Terraform 플러그인 캐시
- *.tfstate - Terraform 상태
- id_rsa* - SSH 키

---

## 파일 관리 가이드

### ⚠️ 민감한 파일 (주의 필요)
1. **Terraform 상태 파일** (*.tfstate)
   - AWS 리소스 정보 포함
   - 민감 정보 포함 가능
   - 자동 생성되므로 백업 시 주의

2. **SSH 키 파일** (id_rsa*, *.ppk)
   - 보안상 외부에 공유하면 안 됨
   - Terraform이 자동 생성

3. **설정 파일** (*.tfvars)
   - 비밀번호 등 민감 정보 포함 가능

### 백업이 필요한 파일
- seoul/variables.yml - 인프라 설정

### 정기적으로 확인할 파일
- seoul/main.tf - 모듈 호출 순서 확인
- modules/*/main.tf - 각 모듈의 리소스 정의

