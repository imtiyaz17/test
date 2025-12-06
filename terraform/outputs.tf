output "api_gateway_arn" {
  value       = module.apigateway.rest_api_arn
  description = "ARN of the API Gateway"
}

output "api_gateway_id" {
  value       = module.apigateway.rest_api_id
  description = "ID of the API Gateway"
}

output "lambda_function_arn" {
  value       = module.lambda_function.lambda_function_arn
  description = "ARN of the Lambda function"
}

output "lambda_exec_role_arn" {
  value       = aws_iam_role.lambda_exec.arn
  description = "ARN of the IAM role for Lambda execution. Use this when configuring your Lambda function to assign it the correct permissions."
}

output "api_gateway_invoke_url" {
  value       = "https://${module.apigateway.rest_api_id}.execute-api.${var.region}.amazonaws.com/${var.stage_name}"
  description = "API Gateway invoke URL"
}

output "lambda_dlq_url" {
  value       = aws_sqs_queue.lambda_dlq.url
  description = "URL of the Lambda Dead Letter Queue for failed Kafka messages"
}

output "lambda_dlq_arn" {
  value       = aws_sqs_queue.lambda_dlq.arn
  description = "ARN of the Lambda Dead Letter Queue"
}

output "replay_lambda_name" {
  value       = module.replay_lambda.lambda_function_name
  description = "Name of the replay Lambda - invoke this to reprocess DLQ messages"
}
