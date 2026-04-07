#!/bin/bash
# ============================================================
# 환경변수 로드 스크립트 (Linux/Mac)
# 
# 사용 방법:
#   source load-env.sh
#   또는
#   . load-env.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    echo "환경변수 파일 로드 중: $ENV_FILE"
    
    # .env 파일에서 환경변수 로드 (주석 제외)
    while IFS='=' read -r key value || [ -n "$key" ]; do
        # 주석이나 빈 줄 건너뛰기
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue
        
        # 앞뒤 공백 제거
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # 환경변수 설정
        export "$key=$value"
        echo "  ✓ $key 설정됨"
    done < <(grep -v '^#' "$ENV_FILE" | grep -v '^$')
    
    echo ""
    echo "환경변수 로드 완료!"
    echo "다음 명령어로 확인: echo \$RDS_PASSWORD, echo \$WORDPRESS_DB_PASSWORD"
else
    echo "경고: .env 파일을 찾을 수 없습니다."
    echo "      .env.example 파일을 복사하여 .env 파일을 생성하세요."
    echo "      예: cp .env.example .env"
fi


