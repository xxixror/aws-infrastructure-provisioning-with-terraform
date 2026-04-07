# ============================================================
# 서울 리전 AWS 인프라 메인 구성 파일
# 프로젝트: WordPress 웹사이트를 위한 고가용성 인프라 구축
# 학습 목표: Terraform을 이용한 Infrastructure as Code (IaC) 실습
# ============================================================

# ------------------------------------------------------------
# 로컬 변수 정의
# 역할: variables.yml 파일을 읽어서 Terraform 변수로 변환
# 학습 포인트: YAML 파일과 Terraform 변수 병합 방법
# ------------------------------------------------------------
locals {
  # YAML 파일을 Terraform 객체로 파싱
  yaml_vars = yamldecode(file("./variables.yml"))
  
  # EC2 인스턴스 개수 병합: terraform 변수로 override 가능
  # terraform apply -var='ec2_instance_counts={web=2}' 형태로 동적 변경 가능
  ec2_instances_merged = {
    for k, v in local.yaml_vars.ec2_instances : k => merge(v, {
      count = lookup(var.ec2_instance_counts, k, v.count)
    })
  }
  
  # RDS 비밀번호 병합: 보안을 위해 환경변수에서 읽어서 사용
  # 환경변수 RDS_PASSWORD가 설정되면 그 값을 사용, 없으면 빈 문자열
  db_instance_merged = merge(
    local.yaml_vars.db_instance,
    { password = var.rds_password }
  )
  
  # 최종 변수: 모든 병합된 값 사용
  vars = merge(local.yaml_vars, {
    ec2_instances = local.ec2_instances_merged
    db_instance   = local.db_instance_merged
  })
}

# ------------------------------------------------------------
# Terraform 및 Provider 설정
# 학습 목표: Terraform 버전 관리 및 Provider 설정 방법
# ------------------------------------------------------------
terraform {
  # Terraform 버전 요구사항 (~> 1.0 = 1.x 버전 사용)
  required_version = "~> 1.0"
  
  required_providers {
    # AWS Provider 설정: AWS 리소스를 관리하기 위한 Provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"  # 6.x 버전 사용
    }
  }

  # Remote State Backend 설정 (현재 주석 처리)
  # 협업 시 S3에 state 파일 저장하고 DynamoDB로 locking 관리
  # 주의: S3 버킷이 삭제되어 현재는 로컬 state 사용
  # backend "s3" {
  #   bucket         = "seoul-s3-js"
  #   key            = "seoul/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   dynamodb_table = "terraform-state-lock-seoul-js"
  #   encrypt        = true
  # }
}

# AWS Provider 설정 - 서울 리전
provider "aws" {
  region = local.vars.region  # ap-northeast-2 (서울)
}

# ============================================================
# 모듈 호출 섹션
# 각 모듈은 독립적인 리소스 그룹을 관리
# 학습 포인트: 모듈화를 통한 코드 재사용성과 유지보수성 향상
# ============================================================

# Terraform Backend 모듈: State 파일 저장소 생성 (S3 + DynamoDB)
module "terraform_backend" {
  count = try(local.vars.terraform_backend.enabled, false) ? 1 : 0
  
  source = "../modules/terraform-backend"
  
  bucket_name         = local.vars.terraform_backend.bucket_name
  dynamodb_table_name = local.vars.terraform_backend.dynamodb_table_name
}

# VPC 모듈: 네트워크 인프라 구축 (VPC, 서브넷, 라우팅 등)
module "vpc" {
  source = "../modules/vpc"
  
  region_name          = local.vars.region_name
  cidr_block           = local.vars.cidr_block
  az_count             = local.vars.az_count
  public_subnet_count  = local.vars.public_subnet_count
  private_subnet_count = local.vars.private_subnet_count
  subnet_bits          = local.vars.subnet_bits
}

# Security Group 모듈: 방화벽 규칙 생성 (web, rds, dns, lb 등)
module "security-group" {
  source = "../modules/security-group"
  
  sg          = local.vars.sg
  vpc_id      = module.vpc.vpc_id
  region_name = local.vars.region_name
}

# Keypair 모듈: SSH 접속용 키 페어 생성
module "keypair" {
  source = "../modules/keypair"
  
  region_name = local.vars.region_name
  key_info    = local.vars.key_info
}

# RDS 모듈: MariaDB 데이터베이스 인스턴스 생성 (WordPress용)
# 프라이빗 서브넷에 배치하여 보안 강화
module "rds" {
  source = "../modules/rds"

  sg_ids           = module.security-group.sg_ids
  db_instance      = local.vars.db_instance
  rds_subnet_group = local.vars.rds_subnet_group
  subnet_ids       = module.vpc.private_subnet_ids
}

# EC2 모듈: 다양한 용도의 EC2 인스턴스 생성 (web, db, dns 등)
module "ec2" {
  source = "../modules/ec2"
  
  region_name        = local.vars.region_name
  key_name           = module.keypair.key_name
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  sg_ids             = module.security-group.sg_ids
  ec2-instances      = local.vars.ec2_instances
}

# SSH 키 파일 저장: 생성된 키를 로컬 파일로 저장 (EC2 인스턴스 접속용)
# 주의: 이 파일들은 .gitignore에 포함되어 Git에 커밋되지 않음
resource "local_file" "private_key" {
  content  = module.keypair.private_key
  filename = "${path.module}/id_${lower(local.vars.key_info.algorithm)}"
  file_permission = "0600"  # 소유자만 읽기/쓰기 가능
}

resource "local_file" "public_key" {
  content  = module.keypair.public_key
  filename = "${path.module}/id_${lower(local.vars.key_info.algorithm)}.pub"
  file_permission = "0644"  # 모든 사용자 읽기 가능
}

# Launch Template 모듈: Auto Scaling용 시작 템플릿 생성
# 역할: Auto Scaling으로 생성될 인스턴스의 설정을 템플릿으로 정의
module "launch_template" {
  source = "../modules/launch_template"
  
  region_name        = local.vars.region_name
  key_name           = module.keypair.key_name
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  sg_ids             = module.security-group.sg_ids
  templates          = local.vars.templates
  ami_images         = local.vars.ami_images
}

# Target Group 모듈: 로드밸런서 대상 그룹 생성
# 역할: 로드밸런서가 트래픽을 분산할 대상 인스턴스 그룹 정의
module "target_group" {
  source = "../modules/target-group"
  
  target_group = local.vars.target_group
  vpc_id       = module.vpc.vpc_id
}

# WAF 모듈: 웹 애플리케이션 방화벽 설정
# 역할: SQL Injection, XSS 등 웹 공격으로부터 보호
module "waf" {
  source = "../modules/waf"

  name                   = local.vars.waf.name
  description            = local.vars.waf.description
  scope                  = local.vars.waf.scope
  default_action         = local.vars.waf.default_action
  rule_name              = local.vars.waf.rule_name
  rule_priority          = local.vars.waf.rule_priority
  rule_override_action   = local.vars.waf.rule_override_action
  managed_rule_vendor    = local.vars.waf.managed_rule_vendor
  managed_rule_name      = local.vars.waf.managed_rule_name
  managed_rules          = try(local.vars.waf.managed_rules, [])
  visibility             = local.vars.waf.visibility
  rule_visibility        = local.vars.waf.rule_visibility
  rate_based_rule        = local.vars.waf.rate_based_rule
}

# Load Balancer 모듈: Application Load Balancer 생성
# 역할: 트래픽을 여러 인스턴스에 분산하여 고가용성 확보
module "load_balancer" {
  source = "../modules/load-balancer"
  
  enable_waf          = true
  waf_acl_arn         = module.waf.waf_arn
  public_subnet_ids   = module.vpc.public_subnet_ids
  sg_ids              = module.security-group.sg_ids
  target_group_arn    = module.target_group.target_group_arn
  load_balancer       = local.vars.load_balancer
  load_balancer_listener = local.vars.load_balancer_listener
}

# Auto Scaling 모듈: 자동 확장/축소 그룹 생성
# 역할: 트래픽에 따라 자동으로 인스턴스 수 조절
module "auto-scaling" {
  source = "../modules/auto-scaling"
  
  public_subnet_ids  = module.vpc.public_subnet_ids
  target_group_arn   = module.target_group.target_group_arn
  lt_ids             = module.launch_template.lt_ids
  autoscaling_group  = local.vars.autoscaling_group
  autoscaling_policy = local.vars.autoscaling_policy
}

# Route53 모듈: 로드밸런서를 사용자 정의 도메인에 연결
# 역할: www.js.it-edu.org 같은 도메인으로 웹사이트 접근 가능
module "route53" {
  source = "../modules/route53"
  
  lb_dns_name = module.load_balancer.lb_dns_name
  rds_endpoint = module.rds.rds
  records = local.vars.route53_records
}
