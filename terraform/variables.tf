#File to Store reusable Variables within the lambda pip module.

variable "region" {
  description = "AWS region for the deployment"
  type        = string
  default     = "us-east-1"
}

variable "runtime" {
  type        = string
  description = "Runtime for the Lambda function"
  default     = "python3.12"
}

variable "vpc_id" {
  type        = string
  description = "ID of existing VPC"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs in the existing VPC"
}

variable "stage_name" {
  type        = string
  description = "API Gateway stage name"
  default     = "dev"
}

variable "oauth_client_id" {
  type        = string
  description = "OAuth client ID for Workday person profile service"
  default     = "p504048"
}

variable "kafka_bootstrap" {
  type        = string
  description = "Kafka bootstrap server URL"
}
