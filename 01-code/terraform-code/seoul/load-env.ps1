# ============================================================
# 환경변수 로드 스크립트 (Windows PowerShell)
# 
# 사용 방법:
#   .\load-env.ps1
# 
# 또는 PowerShell에서:
#   . .\load-env.ps1
# ============================================================

$envFile = Join-Path $PSScriptRoot ".env"

if (Test-Path $envFile) {
    Write-Host "환경변수 파일 로드 중: $envFile" -ForegroundColor Green
    
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
            Write-Host "  ✓ $name 설정됨" -ForegroundColor Gray
            
            # Terraform 변수로 자동 변환 (RDS_PASSWORD -> TF_VAR_rds_password)
            if ($name -eq "RDS_PASSWORD") {
                [Environment]::SetEnvironmentVariable("TF_VAR_rds_password", $value, "Process")
                Write-Host "  ✓ TF_VAR_rds_password 자동 설정됨" -ForegroundColor Gray
            }
            if ($name -eq "WORDPRESS_DB_PASSWORD") {
                [Environment]::SetEnvironmentVariable("TF_VAR_wordpress_db_password", $value, "Process")
                Write-Host "  ✓ TF_VAR_wordpress_db_password 자동 설정됨" -ForegroundColor Gray
            }
        }
    }
    
    # .env 파일이 없어도 직접 설정된 환경변수를 Terraform 변수로 변환
    if ($env:RDS_PASSWORD -and -not $env:TF_VAR_rds_password) {
        [Environment]::SetEnvironmentVariable("TF_VAR_rds_password", $env:RDS_PASSWORD, "Process")
        Write-Host "  ✓ TF_VAR_rds_password 자동 변환됨 (RDS_PASSWORD에서)" -ForegroundColor Gray
    }
    if ($env:WORDPRESS_DB_PASSWORD -and -not $env:TF_VAR_wordpress_db_password) {
        [Environment]::SetEnvironmentVariable("TF_VAR_wordpress_db_password", $env:WORDPRESS_DB_PASSWORD, "Process")
        Write-Host "  ✓ TF_VAR_wordpress_db_password 자동 변환됨 (WORDPRESS_DB_PASSWORD에서)" -ForegroundColor Gray
    }
    
    Write-Host "`n환경변수 로드 완료!" -ForegroundColor Green
    Write-Host "다음 명령어로 확인: `$env:RDS_PASSWORD, `$env:WORDPRESS_DB_PASSWORD" -ForegroundColor Yellow
} else {
    Write-Host "경고: .env 파일을 찾을 수 없습니다." -ForegroundColor Yellow
    Write-Host "      .env.example 파일을 복사하여 .env 파일을 생성하세요." -ForegroundColor Yellow
    Write-Host "      예: Copy-Item .env.example .env" -ForegroundColor Yellow
}

