<!-- BEGIN_TF_DOCS -->

## Special Inputs

Following input variables will be set with automations. You do not have to set them in any `tfvars` file.

1. `environment`
1. `namespace`
1. `region` - Only required to initialize the `aws` provider if it is not explicitly listed for the module inputs.
1. `repo_id`
1. `state_bucket`
1. `state_key`

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.27 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_apigateway"></a> [apigateway](#module\_apigateway) | southwest.gitlab-dedicated.com/swa-common/ccp-next-api-gateway-module/aws | 1.11.0 |
| <a name="module_lambda_function"></a> [lambda\_function](#module\_lambda\_function) | terraform-aws-modules/lambda/aws | 7.21.1 |
| <a name="module_replay_lambda"></a> [replay\_lambda](#module\_replay\_lambda) | terraform-aws-modules/lambda/aws | 7.21.1 |
| <a name="module_root_labels"></a> [root\_labels](#module\_root\_labels) | southwest.gitlab-dedicated.com/swa-common/ccp-next-labels-module/aws | 0.6.1 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.dlq_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_iam_role.apigw_lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.lambda_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.replay_lambda_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.apigw_lambda_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.lambda_cloudwatch_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.lambda_dlq_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.replay_lambda_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.lambda_basic_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_vpc_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.replay_lambda_basic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function_event_invoke_config.async_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_event_invoke_config) | resource |
| [aws_security_group.lambda_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_sqs_queue.lambda_dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_wafv2_web_acl.api_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_secretsmanager_secret_version.kafka_producer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_secretsmanager_secret_version.schema_registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_vpc.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_kafka_bootstrap"></a> [kafka\_bootstrap](#input\_kafka\_bootstrap) | Kafka bootstrap server URL | `string` | n/a |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of private subnet IDs in the existing VPC | `list(string)` | n/a |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of existing VPC | `string` | n/a |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`. This is for some rare cases where resources want additional configuration of tags and therefore take a list of maps with tag key, value, and additional configuration. Check example for ec2 autoscaling group and launch template. | `map(string)` | `{}` |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | Label ID element. Additional attributes to add to `id`, in the order they appear in the list. New attributes are appended to the end of the list. The elements of the list are joined by the `delimiter` and treated as a single ID element. | `list(string)` | `[]` |
| <a name="input_business_service"></a> [business\_service](#input\_business\_service) | CCP Next Tag. Used as `SWA:BusinessService` tag. | `string` | `null` |
| <a name="input_compliance"></a> [compliance](#input\_compliance) | CCP Next Tag. Used as `SWA:Compliance` tag. | `string` | `null` |
| <a name="input_confidentiality"></a> [confidentiality](#input\_confidentiality) | CCP Next Tag. Used as `SWA:Confidentiality` tag. This tag identifies if this is sensitive customer data or confidential business information. | `string` | `null` |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once. See description of individual variables for details. Leave string and numeric variables as `null` to use default value. Individual variable settings (non-null) override settings in context object, except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | ```{ "additional_tag_map": {}, "attributes": [], "business_service": null, "compliance": null, "confidentiality": null, "delimiter": null, "department": null, "descriptor_formats": {}, "enabled": true, "environment": null, "id_length_limit": null, "label_key_case": null, "label_order": [], "label_value_case": null, "labels_as_tags": [ "default" ], "name": null, "namespace": null, "regex_replace_chars": null, "repo_id": null, "state_bucket": null, "state_key": null, "sub_environment": null, "tags": {} }``` |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements. Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` |
| <a name="input_department"></a> [department](#input\_department) | ***(Mandatory)*** Label ID element. The department doing the deployment. Value is normalized and formatted. Also used as `SWA:Name` tag. The value of SWA:Name is the core of reporting data and should capture the referenced SWA product name. E.g. `OpsSuite`, `SWIM`, `CrewBit` or `Baker`. ccp-next-labels-module stops outputting labels and tags if unset. | `string` | `null` |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map. Map of maps. Keys are names of descriptors. Values are maps of the form `{    format = string    labels = list(string) }` (Type is `any` so the map values can later be enhanced to provide additional options.) `format` is a Terraform format string to be passed to the `format()` function. `labels` is a list of labels, in order, to pass to `format()` function. Label values will be normalized before being passed to `format()` so they will be identical to how they appear in `id`. Default is `{}` (`descriptors` output will be empty). | `any` | `{}` |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` |
| <a name="input_environment"></a> [environment](#input\_environment) | ***(Mandatory)*** Label ID element. The environment in which to deploy. Value is normalized and formatted. Also used as `EnvPrefix` tag. ccp-next-labels-module stops outputting labels and tags if unset. | `string` | `null` |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6). Set to `0` for unlimited length. Set to `null` for keep the existing setting, which defaults to `0`. Does not affect `id_full`. | `number` | `null` |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module. Does not affect keys of tags passed in via the `tags` input. Applies only to `attributes` and `name` labels. Possible values: `lower`, `title`, `upper`. Default value: `title`. | `string` | `null` |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`. Defaults to ["department", "environment", "namespace", "name", "attributes"]. You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`, set as tag values, and output by this module individually. Does not affect values of tags passed in via the `tags` input. Possible values: `lower`, `title`, `upper` and `none` (no transformation). Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs. Default value: `lower`. | `string` | `null` |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels to include as tags in the `tags` output. Default is to include all labels. Tags with empty values will not be included in the `tags` output. Set to `[]` to suppress all generated tags. **Notes:**   The value of the `name` tag, if included, will be the `id`, not the `name`. | `set(string)` | ```[ "unset" ]``` |
| <a name="input_name"></a> [name](#input\_name) | Label ID element. Usually the component, service or solution name. This is the only ID element not included as a `tag`. `Name` tag has a special meaning for AWS resources. Value is normalized and formatted. The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | ***(Mandatory)*** Label ID element. The CCP namespace in which to deploy. Value is normalized and formatted. Also used as `CCPNamespace` tag. ccp-next-labels-module stops outputting labels and tags if unset. | `string` | `null` |
| <a name="input_oauth_client_id"></a> [oauth\_client\_id](#input\_oauth\_client\_id) | OAuth client ID for Workday person profile service | `string` | `"p504048"` |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string. Characters matching the regex will be removed from the ID elements. If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | `"us-east-1"` |
| <a name="input_repo_id"></a> [repo\_id](#input\_repo\_id) | ***(Mandatory)*** CCP Next Tag. Used as `RepoId` tag. An identifier from where the AWS resources were deployed. ccp-next-labels-module stops outputting labels and tags if unset. | `string` | `null` |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | Runtime for the Lambda function | `string` | `"python3.12"` |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | API Gateway stage name | `string` | `"dev"` |
| <a name="input_state_bucket"></a> [state\_bucket](#input\_state\_bucket) | ***(Mandatory)*** CCP Next Tag. Used as `TFStateBucket` tag. Specifies AWS s3 bucket name where Terraform state is stored. ccp-next-labels-module stops outputting labels and tags if unset. | `string` | `null` |
| <a name="input_state_key"></a> [state\_key](#input\_state\_key) | ***(Mandatory)*** CCP Next Tag. Used as `TFStateBucket` tag. Specifies AWS s3 prefix where Terraform state is stored. ccp-next-labels-module stops outputting labels and tags if unset. | `string` | `null` |
| <a name="input_sub_environment"></a> [sub\_environment](#input\_sub\_environment) | CCP Next Tag. Used as `SWA:Environment` tag. SWA Accounts are already associated with an environment. | `string` | `null` |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'SWA:Tier': 'app'}`). Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_gateway_arn"></a> [api\_gateway\_arn](#output\_api\_gateway\_arn) | ARN of the API Gateway |
| <a name="output_api_gateway_id"></a> [api\_gateway\_id](#output\_api\_gateway\_id) | ID of the API Gateway |
| <a name="output_api_gateway_invoke_url"></a> [api\_gateway\_invoke\_url](#output\_api\_gateway\_invoke\_url) | API Gateway invoke URL |
| <a name="output_lambda_dlq_arn"></a> [lambda\_dlq\_arn](#output\_lambda\_dlq\_arn) | ARN of the Lambda Dead Letter Queue |
| <a name="output_lambda_dlq_url"></a> [lambda\_dlq\_url](#output\_lambda\_dlq\_url) | URL of the Lambda Dead Letter Queue for failed Kafka messages |
| <a name="output_lambda_exec_role_arn"></a> [lambda\_exec\_role\_arn](#output\_lambda\_exec\_role\_arn) | ARN of the IAM role for Lambda execution. Use this when configuring your Lambda function to assign it the correct permissions. |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | ARN of the Lambda function |
| <a name="output_replay_lambda_name"></a> [replay\_lambda\_name](#output\_replay\_lambda\_name) | Name of the replay Lambda - invoke this to reprocess DLQ messages |
<!-- END_TF_DOCS -->
