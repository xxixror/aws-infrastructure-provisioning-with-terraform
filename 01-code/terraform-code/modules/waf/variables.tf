# ============================================================
# WAF 모듈 입력 변수 정의
# 웹 애플리케이션 방화벽 설정에 필요한 변수들
# ============================================================

variable "name" {
  description = "WAF 이름"
  type        = string
}

variable "description" {
  description = "WAF 설명"
  type        = string
}

variable "scope" {
  description = "WAF scope (REGIONAL or CLOUDFRONT)"
  type        = string
}

variable "default_action" {
  description = "default action: \"allow\" or \"block\""
  type        = string
}

variable "rule_name" {
  description = "내부 룰 이름"
  type        = string
}

variable "rule_priority" {
  description = "룰 우선순위 (숫자)"
  type        = number
}

variable "rule_override_action" {
  description = "룰의 override_action: \"count\"(모니터링) 또는 \"none\"(차단)"
  type        = string
}

variable "managed_rule_vendor" {
  description = "Managed rule vendor"
  type        = string
}

variable "managed_rule_name" {
  description = "Managed rule group name"
  type        = string
}

variable "visibility" {
  description = "WAF 전체 visibility 설정"
  type = object({
    cloudwatch_metrics_enabled = bool
    metric_name                = string
    sampled_requests_enabled   = bool
  })
}

variable "rule_visibility" {
  description = "개별 룰의 visibility 설정"
  type = object({
    cloudwatch_metrics_enabled = bool
    metric_name                = string
    sampled_requests_enabled   = bool
  })
}

variable "managed_rules" {
  description = "Managed rule groups 리스트"
  type = list(object({
    rule_name         = string
    managed_rule_name = string
    priority          = number
    override_action   = string
    vendor            = string
    visibility = object({
      cloudwatch_metrics_enabled = bool
      metric_name                = string
      sampled_requests_enabled   = bool
    })
  }))
  default = []
}

variable "rate_based_rule" {
  description = "Rate-based rule 설정 (브루트포스 공격 방어)"
  type = object({
    enabled                = bool
    rule_name             = string
    rule_priority         = number
    limit                 = number
    evaluation_window_sec = number
    login_paths           = list(string)
    action                = string
    visibility = object({
      cloudwatch_metrics_enabled = bool
      metric_name                = string
      sampled_requests_enabled   = bool
    })
  })
}
