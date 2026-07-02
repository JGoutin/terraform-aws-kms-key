# AWS KMS Key Management Module

[![Terraform Module](https://img.shields.io/badge/Terraform-KMS%20Key%20module-844FBA?logo=terraform&logoColor=ffffff)](https://registry.terraform.io/modules/jgoutin/kms-key/aws/latest)
[![OpenTofu Module](https://img.shields.io/badge/OpenTofu-KMS%20Key%20module-FFDA18?logo=opentofu&logoColor=ffffff)](https://search.opentofu.org/module/jgoutin/kms-key/aws/latest)

Reusable Terraform module for creating and managing AWS KMS Customer Managed Keys with advanced policy merging capabilities.

## Overview

This module simplifies AWS KMS key creation and policy management, with a unique feature for merging multiple policy documents.

**Key Feature:** Dynamic policy merging - combine multiple IAM policy statements from different AWS services into a single KMS key policy.

**Core Capabilities:**
- KMS Customer Managed Key (CMK) creation
- Automatic key rotation (annual)
- Advanced policy document merging
- Multi-region key support

## Features

### KMS Key Management
- ✅ **Customer Managed Keys** - Full control over encryption
- ✅ **Automatic Rotation** - Annual key rotation
- ✅ **Multi-Region Support** - Optional multi-region keys
- ✅ **Key Aliases** - Friendly key names

### Policy Merging
- ✅ **Dynamic Policy Assembly** - Combine policies from multiple sources
- ✅ **Service-Specific Policies** - CloudWatch, S3, ECS, Secrets Manager
- ✅ **Dependency Management** - Control policy update timing
- ✅ **JSON Output** - Export for external use

### Security
- ✅ **Root Account Access** - AWS account root always has access
- ✅ **IAM Integration** - Standard IAM permissions
- ✅ **Service Principals** - AWS service access control
- ✅ **Least Privilege** - Granular permissions

## Quick Start

### Minimal Example

```hcl
module "kms_key" {
  source = "JGoutin/kms-key/aws"
  
  name = "my-encryption-key"
}
```

Creates a KMS key with default policy (root account access only).

### With Policy Documents

```hcl
module "kms_key" {
  source = "JGoutin/kms-key/aws"
  
  name = "app-encryption-key"
  
  policy_documents_json = [
    data.aws_iam_policy_document.s3_encryption.json,
    data.aws_iam_policy_document.cloudwatch_logs.json,
    data.aws_iam_policy_document.ecs_task.json
  ]
}

# S3 bucket encryption policy
data "aws_iam_policy_document" "s3_encryption" {
  statement {
    sid    = "AllowS3BucketEncryption"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["*"]
  }
}

# CloudWatch Logs encryption policy
data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:ReEncrypt*"
    ]
    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:us-east-1:123456789012:log-group:*"]
    }
  }
}
```

### Multi-Region Key

```hcl
module "primary_kms_key" {
  source = "JGoutin/kms-key/aws"
  
  name              = "multi-region-key"
  multi_region      = true
  deletion_window   = 30
}

# Replica in another region
module "replica_kms_key" {
  source = "JGoutin/kms-key/aws"
  
  providers = {
    aws = aws.us_west_2
  }
  
  name                    = "multi-region-key-replica"
  multi_region_replica_of = module.primary_kms_key.arn
}
```

## Architecture

```
┌────────────────────────────────────────────┐
│         KMS Customer Managed Key           │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │         Key Policy                   │  │
│  │  ┌────────────────────────────────┐  │  │
│  │  │  Root Account Access           │  │  │
│  │  │  (Always present)              │  │  │
│  │  └────────────────────────────────┘  │  │
│  │  ┌────────────────────────────────┐  │  │
│  │  │  Service Principal 1           │  │  │
│  │  │  (CloudWatch Logs)             │  │  │
│  │  └────────────────────────────────┘  │  │
│  │  ┌────────────────────────────────┐  │  │
│  │  │  Service Principal 2           │  │  │
│  │  │  (S3)                          │  │  │
│  │  └────────────────────────────────┘  │  │
│  │  ┌────────────────────────────────┐  │  │
│  │  │  IAM Role                      │  │  │
│  │  │  (ECS Task)                    │  │  │
│  │  └────────────────────────────────┘  │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  Automatic Rotation: Enabled               │
│  Deletion Window: 30 days (default)        │
└────────────────────────────────────────────┘
                    │
         ┌──────────┼──────────┐
         │          │          │
    ┌────▼───┐ ┌───▼────┐ ┌──▼─────┐
    │   S3   │ │  Logs  │ │  ECS   │
    │Buckets │ │ Groups │ │ Tasks  │
    └────────┘ └────────┘ └────────┘
```

## Policy Merging

The module merges multiple policy documents into a single KMS key policy:

```hcl
# Input: Array of policy JSON documents
policy_documents_json = [
  policy_doc_1.json,  # CloudWatch statement
  policy_doc_2.json,  # S3 statement
  policy_doc_3.json   # ECS statement
]

# Output: Single merged policy with all statements
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     { /* Root account access */ },
#     { /* CloudWatch statement */ },
#     { /* S3 statement */ },
#     { /* ECS statement */ }
#   ]
# }
```

## Use Cases

### CloudWatch Logs Encryption

```hcl
module "kms_key" {
  source = "JGoutin/kms-key/aws"
  name   = "cloudwatch-encryption"
  
  policy_documents_json = [
    data.aws_iam_policy_document.cloudwatch_logs.json
  ]
}

data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    sid = "AllowCloudWatchLogs"
    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com"]
    }
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey"]
    resources = ["*"]
  }
}

resource "aws_cloudwatch_log_group" "encrypted" {
  name              = "/aws/app/logs"
  kms_key_id        = module.kms_key.arn
  retention_in_days = 90
}
```

### S3 Bucket Encryption

```hcl
module "kms_key" {
  source = "JGoutin/kms-key/aws"
  name   = "s3-encryption"
  
  policy_documents_json = [
    data.aws_iam_policy_document.s3.json
  ]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypted" {
  bucket = aws_s3_bucket.main.id
  
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
```

### ECS Task Encryption

```hcl
module "kms_key" {
  source = "JGoutin/kms-key/aws"
  name   = "ecs-encryption"
  
  policy_documents_json = [
    data.aws_iam_policy_document.ecs_task.json
  ]
}

data "aws_iam_policy_document" "ecs_task" {
  statement {
    sid = "AllowECSTask"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ecs_task.arn]
    }
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = ["*"]
  }
}
```

## Dependency Management

Use `policy_dependency` output to control resource creation order:

```hcl
module "kms_key" {
  source = "JGoutin/kms-key/aws"
  name   = "app-key"
  
  policy_documents_json = [
    data.aws_iam_policy_document.app.json
  ]
}

# Wait for KMS policy to be updated before creating resource
resource "aws_s3_bucket" "encrypted" {
  bucket = "my-encrypted-bucket"
  
  # Ensure KMS policy allows S3 access before bucket is created
  depends_on = [module.kms_key.policy_dependency]
}
```

## Key Rotation

Automatic key rotation is enabled by default:

- **Rotation Period**: 365 days (1 year)
- **Old Keys**: Retained for decryption
- **No Downtime**: Seamless rotation
- **AWS Managed**: Automatic process

Disable for compliance:

```hcl
module "kms_key" {
  source          = "JGoutin/kms-key/aws"
  name            = "no-rotation-key"
  enable_rotation = false
}
```

## Deletion Protection

Default deletion window: 30 days

```hcl
module "kms_key" {
  source          = "JGoutin/kms-key/aws"
  name            = "protected-key"
  deletion_window = 30  # 7-30 days
}
```

**Terraform destroy** behavior:
- Schedules key for deletion
- Key enters "PendingDeletion" state
- Can be canceled during window
- Automatic deletion after window expires

## Outputs

Key outputs for integration:

- `id` - KMS key ID (for API calls)
- `arn` - KMS key ARN (for resource configuration)
- `alias_arn` - Key alias ARN (for IAM policies)
- `policy_documents_json` - Merged policy JSON (for external use)
- `policy_dependency` - Dependency anchor (for resource ordering)

## Requirements

- **Terraform/OpenTofu**: >= 1.5.0
- **AWS Provider**: >= 6.27.0
- **Permissions**: `kms:CreateKey`, `kms:PutKeyPolicy`, `kms:CreateAlias`

## Best Practices

1. **Enable Rotation** - Keep automatic key rotation enabled for enhanced security
2. **Use Policy Merging** - Leverage the policy merging feature for complex multi-service scenarios
3. **Set Deletion Window** - Use 30-day deletion window for production keys
4. **Tag Resources** - Apply consistent tags for cost allocation and governance
5. **Monitor Usage** - Track key usage and API calls via CloudWatch
6. **Use Aliases** - Create meaningful aliases for easier key identification

---

# Terraform Documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.27.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.27.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_kms_alias.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_key.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_id"></a> [id](#input\_id) | If specified, directly use this KMS key instead of creating a dedicated one for the application. | `string` | `null` | no |
| <a name="input_multi_region"></a> [multi\_region](#input\_multi\_region) | Indicates whether the KMS key is a multi-Region (true) or regional (false) key. | `bool` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Name to use as KMS key alias. | `string` | n/a | yes |
| <a name="input_policy_dependency"></a> [policy\_dependency](#input\_policy\_dependency) | Used to ensure resource creation dependency. List of 'aws\_kms\_key\_policy' resource for the KMS key specified using var.id, used to be configured with 'policy\_documents\_json' output value from this module. | `list(any)` | `[]` | no |
| <a name="input_policy_documents_json"></a> [policy\_documents\_json](#input\_policy\_documents\_json) | Policy JSON documents to merge together and set as the key policy. | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region where the KMS key is created. If null, falls back to the provider's configured region. Requires AWS provider >= 6.0.0. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to created resources. | `map(string)` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | KMS key ARN. |
| <a name="output_id"></a> [id](#output\_id) | KMS key ID. |
| <a name="output_policy_dependency"></a> [policy\_dependency](#output\_policy\_dependency) | To use with 'depends\_on' for resources requiring that KMS policy from this module is updated before creation. |
| <a name="output_policy_documents_json"></a> [policy\_documents\_json](#output\_policy\_documents\_json) | Policy JSON documents to merge together and set as policy for the user specified key. Only if var.id is defined. |
<!-- END_TF_DOCS -->