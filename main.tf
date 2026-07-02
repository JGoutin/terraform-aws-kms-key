/*
KMS key
*/

locals {
  kms_key_create              = var.id == null
  kms_key_create_count        = local.kms_key_create ? 1 : 0
  kms_key_policy_enabled      = local.kms_key_create && length(var.policy_documents_json) > 0
  kms_key_create_policy_count = local.kms_key_policy_enabled ? 1 : 0
}

/*
Reuse user defined KMS key
 */

data "aws_kms_key" "main" {
  count  = local.kms_key_create ? 0 : 1
  key_id = var.id
  region = var.region
}

/*
Create a new KMS key
*/

locals {
  name = "${var.name_prefix}-${data.aws_region.current.region}-kms-key"
}

resource "aws_kms_key" "main" {
  count               = local.kms_key_create_count
  description         = "${local.name} encryption key"
  enable_key_rotation = true
  multi_region        = var.multi_region
  region              = var.region
  tags                = var.tags
}

resource "aws_kms_alias" "main" {
  count         = local.kms_key_create_count
  name          = "alias/${local.name}"
  target_key_id = aws_kms_key.main[0].id
  region        = var.region
}

# Policy

resource "aws_kms_key_policy" "main" {
  count  = local.kms_key_create_policy_count
  key_id = aws_kms_key.main[0].id
  policy = data.aws_iam_policy_document.main[0].json
  region = var.region
}

data "aws_iam_policy_document" "main" {
  count     = local.kms_key_create_policy_count
  policy_id = var.name_prefix
  source_policy_documents = concat(
    [data.aws_iam_policy_document.default[0].json],
    var.policy_documents_json
  )
}

data "aws_iam_policy_document" "default" {
  count     = local.kms_key_create_policy_count
  policy_id = "default"
  statement {
    sid = "Enable IAM User Permissions"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      type        = "AWS"
    }
    actions   = ["kms:*"]
    resources = [aws_kms_key.main[0].arn]
  }
}


/*
Common data
*/

data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  region = var.region
}
