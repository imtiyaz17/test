locals {
  bucket_name = "swa-devops-${data.aws_caller_identity.current.account_id}-${var.region}" # for lambda code, not state
}

# Minimal WAF for API Gateway - allows all traffic
resource "aws_wafv2_web_acl" "api_protection" {
  name  = "${module.root_labels.id}-api-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }
  # Add Log4j2 protection rule
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "KnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${module.root_labels.id}-api-waf"
    sampled_requests_enabled   = false
  }

  tags = {
    Name = "${module.root_labels.id}-api-waf"
  }
}


# Use existing VPC
data "aws_vpc" "existing" {
  id = var.vpc_id
}




module "apigateway" {
  source        = "southwest.gitlab-dedicated.com/swa-common/ccp-next-api-gateway-module/aws"
  version       = "1.11.0"
  context       = module.root_labels.context
  api_name      = "${module.root_labels.id}-calm-apigw"
  endpoint_type = "REGIONAL"
  wafv2_arn     = aws_wafv2_web_acl.api_protection.arn

  resource_policies = [
    {
      effect    = "Allow"
      actions   = ["execute-api:Invoke"]
      resources = ["*/*"]
      principals = [
        {
          identifiers = ["*"]
          type        = "AWS"
        }
      ]
    }
  ]

  file_spec_path = "../api_spec.yml"
  file_spec_vars = {
    lambda_arn      = module.lambda_function.lambda_function_arn
    apigw_role_name = aws_iam_role.apigw_lambda_role.name
    oauth_issuer    = "https://sso.fed.${module.root_labels.environment}.aws.swacorp.com"
    oauth_audience  = "aud://sso.fed.${module.root_labels.environment}.aws.swacorp.com/workday/${var.oauth_client_id}"
  }

  stages = {
    (var.stage_name) = {
      name = var.stage_name
    }
  }

  depends_on = [module.lambda_function]
}

# Dead Letter Queue for failed Kafka messages (final destination)
resource "aws_sqs_queue" "lambda_dlq" {
  name                       = "${module.root_labels.id}-lambda-dlq"
  message_retention_seconds  = 1209600 # 14 days
  visibility_timeout_seconds = 300
  kms_master_key_id          = "alias/aws/sqs"

  tags = merge(
    module.root_labels.tags,
    {
      Name = "${module.root_labels.id}-lambda-dlq"
    }
  )
}

# CloudWatch Alarm for DLQ messages
resource "aws_cloudwatch_metric_alarm" "dlq_alarm" {
  alarm_name          = "${module.root_labels.id}-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Alert when messages appear in DLQ"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.lambda_dlq.name
  }

  alarm_actions = [] # Add SNS topic ARN here for notifications

  tags = module.root_labels.tags
}

## Lambda
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.21.1"

  function_name = "${module.root_labels.id}-apigw-lambda"
  description   = "POC Lambda for API GW Testing"
  handler       = "lambda_function.lambda_handler"
  runtime       = var.runtime
  timeout       = 30

  # Whether to publish creation/change as new Lambda Function Version.
  publish = true

  # Use IAM role created below
  create_role = false
  lambda_role = aws_iam_role.lambda_exec.arn

  # VPC Configuration - Lambda inside VPC
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.lambda_sg.id]

  source_path = "${path.module}/../src"

  store_on_s3 = true
  s3_bucket   = local.bucket_name
  s3_prefix   = "lambda/"

  tracing_mode = "Active"

  environment_variables = {
    KAFKA_API_KEY              = local.kafka_producer_secrets.key
    KAFKA_API_SECRET           = local.kafka_producer_secrets.secret
    KAFKA_BOOTSTRAP            = var.kafka_bootstrap
    SCHEMA_REGISTRY_API_KEY    = local.schema_registry_secrets.key
    SCHEMA_REGISTRY_API_SECRET = local.schema_registry_secrets.secret
    SCHEMA_REGISTRY_URL        = local.schema_registry_proxy_url
    NAMESPACE                  = var.namespace
  }

  tags = {
    Module = "lambda-with-apigw"
  }
}

# Lambda async invocation config - retry and DLQ
resource "aws_lambda_function_event_invoke_config" "async_config" {
  function_name = module.lambda_function.lambda_function_name

  maximum_retry_attempts       = 2    # Retry twice on failure
  maximum_event_age_in_seconds = 3600 # Discard after 1 hour

  destination_config {
    on_failure {
      destination = aws_sqs_queue.lambda_dlq.arn
    }
  }

  depends_on = [module.lambda_function]
}



# IAM Role for Lambda Execution
# This role allows AWS Lambda to assume it and execute the function
resource "aws_iam_role" "lambda_exec" {
  name = "${module.root_labels.id}-apigw-lambda-role"

  # Trust relationship policy allowing Lambda to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole" # Allow the use of the AssumeRole action
      Effect = "Allow"          # This is an allowance, not a denial
      Principal = {
        Service = "lambda.amazonaws.com" # AWS Lambda service can assume this role
      }
    }]
  })
}

# Security group for Lambda
resource "aws_security_group" "lambda_sg" {
  name        = "${module.root_labels.id}-kafka-producer-sg"
  description = "Security group for Lambda Kafka producer"
  vpc_id      = data.aws_vpc.existing.id

  # HTTPS for schema registry
  egress {
    description = "schema registry"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kafka broker
  egress {
    description = "Kafka broker access"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = module.root_labels.tags
}

# Attach AWS managed policy for basic Lambda execution
# This policy provides permissions for creating CloudWatch logs
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach VPC execution policy for Lambda in VPC
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# IAM policy for Lambda to send to DLQ on async failure
resource "aws_iam_role_policy" "lambda_dlq_policy" {
  name = "${module.root_labels.id}-lambda-dlq-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.lambda_dlq.arn
      }
    ]
  })
}

# IAM policy for Lambda to publish CloudWatch metrics
resource "aws_iam_role_policy" "lambda_cloudwatch_policy" {
  name = "${module.root_labels.id}-lambda-cloudwatch-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM role for API Gateway to invoke Lambda
resource "aws_iam_role" "apigw_lambda_role" {
  name = "${module.root_labels.id}-apigw-invoke-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "apigw_lambda_policy" {
  name = "${module.root_labels.id}-apigw-lambda-policy"
  role = aws_iam_role.apigw_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "lambda:InvokeFunction"
      ]
      Resource = module.lambda_function.lambda_function_arn
    }]
  })
}

## Replay Lambda - manually invoke to reprocess DLQ messages
module "replay_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.21.1"

  function_name = "${module.root_labels.id}-dlq-replay"
  description   = "Manually replay DLQ messages"
  handler       = "replay_dlq_lambda.lambda_handler"
  runtime       = var.runtime
  timeout       = 300 # 5 min for bulk replay

  create_role = false
  lambda_role = aws_iam_role.replay_lambda_exec.arn

  source_path = [
    {
      path = "${path.module}/../replay_dlq_lambda.py"
    }
  ]

  store_on_s3 = true
  s3_bucket   = local.bucket_name
  s3_prefix   = "lambda/"

  tracing_mode = "Active"

  environment_variables = {
    DLQ_URL            = aws_sqs_queue.lambda_dlq.url
    TARGET_LAMBDA_NAME = module.lambda_function.lambda_function_name
  }

  tags = {
    Module = "dlq-replay"
  }
}

# IAM Role for Replay Lambda
resource "aws_iam_role" "replay_lambda_exec" {
  name = "${module.root_labels.id}-replay-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "replay_lambda_basic" {
  role       = aws_iam_role.replay_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Replay Lambda permissions
resource "aws_iam_role_policy" "replay_lambda_policy" {
  name = "${module.root_labels.id}-replay-lambda-policy"
  role = aws_iam_role.replay_lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.lambda_dlq.arn
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = module.lambda_function.lambda_function_arn
      }
    ]
  })
}
