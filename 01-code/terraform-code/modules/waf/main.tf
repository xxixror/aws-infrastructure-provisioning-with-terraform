# ============================================================
# WAF 모듈 - AWS WAFv2 Web ACL 생성 (블로그 DVWA 예시와 비교)
# 블로그: DVWA용 하드코딩된 WAF (이름/룰 고정, 재사용 어려움)
# 이 코드: WordPress용 변수화 (seoul/variables.yml에서 설정, 모듈화로 재사용 가능)
# ============================================================

# AWS WAFv2 Web ACL 리소스 생성
# 블로그: "wordpress-sql-waf"처럼 하드코딩
# 이 코드: var.name으로 변수화하여 외부 설정 가능
resource "aws_wafv2_web_acl" "wp_waf" {
  name        = var.name  # 블로그: 하드코딩 ("wordpress-sql-waf") / 이 코드: 변수로 유연하게 변경
  description = var.description  # 블로그: 하드코딩 설명 / 이 코드: 변수로 설명 변경 가능
  scope       = var.scope  #작용범위는 리저

  # 기본 액션 설정: 모든 요청에 대한 기본 동작
  # 이 코드: dynamic으로 변수에 따라 allow/block 조건부 적용 (테스트/운영 모드 전환 용이)
  default_action {   # 아래 정의할 규칙에 하나도 걸리지 않은 나머지 요청을 어떻게 처리할건지
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }
    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

 # 규칙!!
  # 기존 단일 rule (하위 호환성을 위해 유지)
  dynamic "rule" {
    for_each = var.managed_rule_name != "" && length(var.managed_rules) == 0 ? [1] : []
    content {
      name     = var.rule_name  # 이름
      priority = var.rule_priority  # 우선순위 우리는 하나만 할거임

      # 룰 오버라이드 액션
      # 규칙이 탐지되었을때 적용 
      override_action {
        dynamic "count" {  #공격을 감지해도 차단하지 않고 숫자만 셉니다(로그 확인용).
          for_each = var.rule_override_action == "count" ? [1] : []
          content {}
        }
        dynamic "none" {  # 규칙에 정의된 본래 동작(차단 등)을 그대로 수행합니다.
          for_each = var.rule_override_action == "none" ? [1] : []
          content {}
        }
      }

      # 룰 스테이트먼트: 관리형 룰 그룹
      # AWS가 미리 만들어둔 보안 규칙 셋을 사용하겠다
      statement {
        managed_rule_group_statement {
          vendor_name = var.managed_rule_vendor  # 
          name        = var.managed_rule_name     #  "AWSManagedRulesSQLiRuleSet" 룰을 사용
        }
      }

      # 룰별 가시성 설정
      # CloudWatch 지표로 볼 것인지, 실제 어떤 요청들이었는지 샘플을 수집할 것인지 설정합니다.
      visibility_config {
        cloudwatch_metrics_enabled = var.rule_visibility.cloudwatch_metrics_enabled
        metric_name                = var.rule_visibility.metric_name  # 블로그: "SQLiRuleMetric" 하드코딩 / 이 코드: 변수
        sampled_requests_enabled   = var.rule_visibility.sampled_requests_enabled
      }
    }
  }

  # 여러 Managed Rule을 동적으로 생성
  dynamic "rule" {
    for_each = var.managed_rules
    content {
      name     = rule.value.rule_name  # WAF rule의 이름
      priority = rule.value.priority

      # 룰 오버라이드 액션
      override_action {
        dynamic "count" {
          for_each = rule.value.override_action == "count" ? [1] : []
          content {}
        }
        dynamic "none" {
          for_each = rule.value.override_action == "none" ? [1] : []
          content {}
        }
      }

      # 룰 스테이트먼트: 관리형 룰 그룹
      statement {
        managed_rule_group_statement {
          vendor_name = rule.value.vendor
          name        = rule.value.managed_rule_name  # AWS managed rule 이름
        }
      }

      # 룰별 가시성 설정
      visibility_config {
        cloudwatch_metrics_enabled = rule.value.visibility.cloudwatch_metrics_enabled
        metric_name                = rule.value.visibility.metric_name
        sampled_requests_enabled   = rule.value.visibility.sampled_requests_enabled
      }
    }
  }

  # Rate-based Rule (브루트포스 공격 방어)
  # 짧은 시간 내에 15회 이상 로그인 시도 시 차단
  # 
  # 차단 해제 동작:
  # - 평가 기간(evaluation_window_sec) 동안 요청 수를 추적합니다
  # - limit을 초과하면 해당 IP가 자동으로 차단됩니다
  # - 차단 해제는 AWS가 자동으로 관리하며, 일반적으로 평가 기간 동안 지속됩니다
  # - 요청 속도가 임계값(limit) 아래로 떨어지면 자동으로 차단이 해제됩니다
  # - 예: 5분 평가 기간에서 15회 초과 시 차단 → 5분 후 요청 속도가 낮아지면 자동 해제
  dynamic "rule" {
    for_each = var.rate_based_rule.enabled ? [1] : []
    content {
      name     = var.rate_based_rule.rule_name
      priority = var.rate_based_rule.rule_priority

      # Rate-based rule 액션 설정
      action {
        dynamic "block" {
          for_each = var.rate_based_rule.action == "block" ? [1] : []
          content {}
        }
        dynamic "count" {
          for_each = var.rate_based_rule.action == "count" ? [1] : []
          content {}
        }
      }

      # Rate-based rule 스테이트먼트
      statement {
        rate_based_statement {
          limit              = var.rate_based_rule.limit
          aggregate_key_type = "IP"  # IP 주소 기반으로 요청 수 추적

          # 로그인 경로만 타겟팅 (scope-down statement)
          # 여러 로그인 경로를 지원하기 위해 or_statement 사용
          scope_down_statement {
            or_statement {
              dynamic "statement" {
                for_each = var.rate_based_rule.login_paths
                content {
                  byte_match_statement {
                    positional_constraint = "CONTAINS"
                    search_string         = statement.value

                    field_to_match {
                      uri_path {}
                    }

                    text_transformation {
                      priority = 0
                      type     = "LOWERCASE"
                    }
                  }
                }
              }
            }
          }
        }
      }

      # Rate-based rule 가시성 설정
      visibility_config {
        cloudwatch_metrics_enabled = var.rate_based_rule.visibility.cloudwatch_metrics_enabled
        metric_name                = var.rate_based_rule.visibility.metric_name
        sampled_requests_enabled   = var.rate_based_rule.visibility.sampled_requests_enabled
      }
    }
  }

  # 전체 ACL 가시성 설정
  # **'Web ACL 전체'**에 대한 통합 모니터링 설정입니다. 전체 트래픽의 허용/차단 통계를 CloudWatch에서 확인할 때 사용
  visibility_config {
    cloudwatch_metrics_enabled = var.visibility.cloudwatch_metrics_enabled
    metric_name                = var.visibility.metric_name  # 블로그: "WordPressWAF" 하드코딩 / 이 코드: 변수
    sampled_requests_enabled   = var.visibility.sampled_requests_enabled
  }
}

# 결과
# WAF & Shield > Web ACLs > *리전(예: Seoul)**을 선택해야 리스트
# 웹에서 ' OR 1=1 -- 같은 SQL 주입 코드 rule_override_action = count (웹은 평소처럼 동작하지만 로그가 남음 ) / none에 따라 달라짐
# count (웹은 평소처럼 동작하지만 로그가 남음 ) = CloudWatch 메트릭에 "이 요청은 SQLi 규칙에 걸렸음"이라고 숫자만 셉니다.

# 로그 보는 곳 
# WAF & Shield >  Web ACLs > 리소스 클릭 > Overview > Sampled requests
# 여기서 어떤 IP가, 어떤 URL로, 어떤 SQL 공격 패턴을 시도했는지 리스트로 보여줍니다.

# 차단된 요청은 Action 열에 BLOCK이라고 표시됩니다.

# 2. 전체 상세 로그 확인 (CloudWatch Logs)
# 만약 모든 접속 기록을 저장하고 분석하고 싶다면, 테라폼 코드 외에 **'Logging Configuration'**이라는 설정을 추가로 해주어야 합니다. (현재 코드에는 로그 저장소 연결 부분이 빠져 있습니다.)

# 만약 로그 저장을 설정했다면 다음 위치에서 볼 수 있습니다.

# CloudWatch 서비스로 이동합니다.

# 왼쪽 메뉴에서 Logs > Log groups를 클릭합니다.

# /aws/waf/로 시작하는 로그 그룹을 찾습니다.

# Logs Insights를 사용하면 "어떤 SQL 규칙에 가장 많이 걸렸는지" 등을 쿼리로 분석할 수 있습니다.