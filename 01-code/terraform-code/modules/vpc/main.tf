# ============================================================
# VPC 모듈
# 프로젝트 목적: AWS 네트워크 인프라 구성 (VPC, 서브넷, 라우팅)
# 학습 목표: VPC 네트워킹 기본 개념 이해
# ============================================================

# ------------------------------------------------------------
# VPC (Virtual Private Cloud) 리소스
# 역할: AWS 내 격리된 가상 네트워크 환경 구축
# 학습 포인트: CIDR 블록과 DNS 설정
# ------------------------------------------------------------
resource "aws_vpc" "main" {
  # CIDR 블록: VPC 내에서 사용할 IP 주소 범위
  # 예: "10.2.0.0/16" = 10.2.0.0 ~ 10.2.255.255 (65,536개 IP)
  cidr_block = var.cidr_block
  
  # DNS 호스트네임 활성화: EC2 인스턴스에 퍼블릭 DNS 호스트네임 자동 할당
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.region_name}-vpc-js"
  }
}

# ------------------------------------------------------------
# 가용영역(Availability Zone) 데이터 소스
# 역할: 현재 리전에서 사용 가능한 가용영역 목록 조회
# 학습 포인트: data 소스를 통한 AWS 정보 조회
# ------------------------------------------------------------
data "aws_availability_zones" "zones" {}

# 가용영역 목록을 지정된 개수만큼 추출
locals {
  # slice 함수: 리스트에서 0번째부터 az_count개 만큼의 요소 추출
  # 예: ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"] → 2개만 사용
  az_list = slice(data.aws_availability_zones.zones.names, 0, var.az_count)
}

# ------------------------------------------------------------
# 퍼블릭 서브넷 생성
# 역할: 인터넷 게이트웨이를 통해 외부와 직접 통신 가능한 서브넷
# 학습 포인트: 퍼블릭 서브넷 vs 프라이빗 서브넷 차이
# ------------------------------------------------------------
resource "aws_subnet" "publics" {
  count = var.public_subnet_count

  # 소속 VPC 지정
  vpc_id = aws_vpc.main.id
  
  # 가용영역 분산 배치: 인덱스를 가용영역 개수로 나눈 나머지로 순환 배치
  # 예: 2개 서브넷, 2개 AZ → 각각 다른 AZ에 배치
  availability_zone = local.az_list[count.index % var.az_count]
  
  # CIDR 블록 자동 계산: cidrsubnet(베이스CIDR, 추가비트, 서브넷번호)
  # 예: 10.2.0.0/16 + 8비트 = 10.2.0.0/24, 10.2.1.0/24 등
  # 각 서브넷당 256개 IP 할당 (10.2.0.0 ~ 10.2.0.255)
  cidr_block = cidrsubnet(var.cidr_block, var.subnet_bits, count.index)
  
  # 인스턴스 시작 시 자동으로 퍼블릭 IP 할당
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.region_name}-public-subnet-js-${count.index + 1}"
  }
}

# ------------------------------------------------------------
# 프라이빗 서브넷 생성
# 역할: 외부에서 직접 접근 불가, NAT 게이트웨이 통해 아웃바운드만 가능
# 학습 포인트: 보안을 위한 프라이빗 서브넷 활용 (RDS 배치)
# ------------------------------------------------------------
resource "aws_subnet" "privates" {
  count = var.private_subnet_count

  vpc_id = aws_vpc.main.id
  
  # 가용영역 순환 배치
  availability_zone = local.az_list[count.index % var.az_count]
  
  # CIDR 블록: 퍼블릭 서브넷과 겹치지 않도록 상위 절반 IP 대역 사용
  # pow(2, subnet_bits -1) = 128 (8비트 기준)
  # 즉, 10.2.128.0/24부터 시작하여 퍼블릭 서브넷과 분리
  cidr_block = cidrsubnet(var.cidr_block, var.subnet_bits, pow(2, var.subnet_bits - 1) + count.index)
  
  # 퍼블릭 IP 자동 할당 비활성화 (프라이빗이므로)
  map_public_ip_on_launch = false
  
  tags = {
    Name = "${var.region_name}-private-subnet-js-${count.index + 1}"
  }
}

# ------------------------------------------------------------
# 인터넷 게이트웨이(IGW) 생성
# 역할: VPC와 인터넷 간의 통신을 가능하게 하는 게이트웨이
# 학습 포인트: 퍼블릭 서브넷이 인터넷에 접근하는 방법
# ------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.region_name}-igw-js"
  }
}

# ------------------------------------------------------------
# 퍼블릭 라우팅 테이블 생성
# 역할: 퍼블릭 서브넷의 트래픽 라우팅 규칙 정의
# 학습 포인트: 라우팅 테이블을 통한 트래픽 경로 제어
# ------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  # 기본 라우트: 모든 외부 트래픽(0.0.0.0/0)을 인터넷 게이트웨이로 전송
  # 이 설정으로 퍼블릭 서브넷의 인스턴스가 인터넷에 접근 가능
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "${var.region_name}-public-route-js"
  }
}

# ------------------------------------------------------------
# 프라이빗 라우팅 테이블 생성
# 역할: 프라이빗 서브넷별로 개별 라우팅 테이블 생성
# 학습 포인트: 프라이빗 서브넷은 NAT 게이트웨이 필요 (현재 미설정)
# ------------------------------------------------------------
resource "aws_route_table" "privates" {
  count = var.private_subnet_count

  vpc_id = aws_vpc.main.id
  
  # 현재 NAT 게이트웨이 라우트는 미설정
  # 필요 시 NAT 게이트웨이를 추가하여 프라이빗 서브넷의 아웃바운드 트래픽 허용 가능
  
  tags = {
    Name = "${var.region_name}-private-route-js-${count.index + 1}"
  }
}

# ------------------------------------------------------------
# 퍼블릭 서브넷 ↔ 퍼블릭 라우팅 테이블 연결
# 역할: 모든 퍼블릭 서브넷이 동일한 라우팅 테이블 공유
# 학습 포인트: 라우팅 테이블 연결을 통한 트래픽 경로 설정
# ------------------------------------------------------------
resource "aws_route_table_association" "public" {
  count = var.public_subnet_count

  # 공통 퍼블릭 라우팅 테이블 연결
  route_table_id = aws_route_table.public.id
  
  # 해당 인덱스의 퍼블릭 서브넷 연결
  subnet_id = aws_subnet.publics[count.index].id
}

# ------------------------------------------------------------
# 프라이빗 서브넷 ↔ 프라이빗 라우팅 테이블 연결
# 역할: 각 프라이빗 서브넷에 개별 라우팅 테이블 연결
# 학습 포인트: 서브넷별 독립적인 라우팅 설정 가능
# ------------------------------------------------------------
resource "aws_route_table_association" "privates" {
  count = var.private_subnet_count

  # 해당 인덱스의 프라이빗 라우팅 테이블 연결
  route_table_id = aws_route_table.privates[count.index].id
  
  # 해당 인덱스의 프라이빗 서브넷 연결
  subnet_id = aws_subnet.privates[count.index].id
}
