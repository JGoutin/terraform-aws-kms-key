output "id" {
  description = "KMS key ID."
  value       = coalesce(local.kms_key_create ? aws_kms_key.main[0].key_id : data.aws_kms_key.main[0].key_id)
}

output "arn" {
  description = "KMS key ARN."
  value       = coalesce(local.kms_key_create ? aws_kms_key.main[0].arn : data.aws_kms_key.main[0].arn)
}

output "policy_documents_json" {
  description = "Policy JSON documents to merge together and set as policy for the user specified key. Only if var.id is defined."
  value       = local.kms_key_policy_enabled ? [] : var.policy_documents_json
}

output "policy_dependency" {
  description = "To use with 'depends_on' for resources requiring that KMS policy from this module is updated before creation."
  value       = local.kms_key_policy_enabled ? aws_kms_key_policy.main[*] : var.policy_dependency
}
