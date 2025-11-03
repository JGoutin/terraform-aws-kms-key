variable "name_prefix" {
  description = "Name to use as KMS key alias."
  type        = string
}

variable "id" {
  description = "If specified, directly use this KMS key instead of creating a dedicated one for the application."
  type        = string
  default     = null
}

variable "policy_documents_json" {
  description = "Policy JSON documents to merge together and set as the key policy."
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
