variable "name_prefix" {
  description = "Name to use as KMS key alias."
  type        = string
}

variable "id" {
  description = "If specified, directly use this KMS key instead of creating a dedicated one for the application. Security Hub: when set, KMS.3/KMS.4/KMS.5 for this key become the responsibility of whatever created it — this module no longer manages its rotation or policy."
  type        = string
  default     = null
}

variable "policy_documents_json" {
  description = "Policy JSON documents to merge together and set as the key policy. Security Hub: KMS.5 (KMS keys should not be publicly accessible) — default [] = pass (root-account-only policy); a statement with Principal \"*\" / AWS: \"*\" without a restrictive Condition fails this control, since documents are merged into the key policy without validation."
  type        = list(string)
  default     = []
}

variable "policy_dependency" {
  description = "Used to ensure resource creation dependency. List of 'aws_kms_key_policy' resource for the KMS key specified using var.id, used to be configured with 'policy_documents_json' output value from this module."
  type        = list(any)
  default     = []
}

variable "multi_region" {
  description = "Indicates whether the KMS key is a multi-Region (true) or regional (false) key."
  type        = bool
  default     = null
}

variable "region" {
  description = "AWS region where the KMS key is created. If null, falls back to the provider's configured region. Requires AWS provider >= 6.0.0."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to created resources."
  type        = map(string)
  default     = null
}
