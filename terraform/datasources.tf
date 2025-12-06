data "aws_caller_identity" "current" {}

locals {
  # Construct environment prefix from environment and region
  region_suffix  = var.region == "us-east-1" ? "east" : "west"
  env_prefix     = "${var.environment}-${local.region_suffix}"
  cluster_suffix = "${local.env_prefix}.${var.region}.enterprise.dedicated"

  # Schema Registry Proxy URL with caching
  schema_registry_proxy_url = var.region == "us-east-1" ? "https://kafka-schema-caching.ehub.${var.environment}-network.${var.environment}.aws.swacorp.com/ehub/ops/schemaCache/eastEndpoint/producer.people.workdayPersonProfile" : "https://kafka-schema-caching.ehub.${var.environment}-network.${var.environment}.aws.swacorp.com/ehub/ops/schemaCache/westEndpoint/producer.people.workdayPersonProfile"
}

# Kafka producer credentials
data "aws_secretsmanager_secret_version" "kafka_producer" {
  secret_id = "/confluent/kafka/${local.env_prefix}/${local.cluster_suffix}/producer.people.workdayPersonProfile"
}

# Schema Registry credentials
data "aws_secretsmanager_secret_version" "schema_registry" {
  secret_id = "/confluent/kafka/${local.env_prefix}/schemaRegistry/producer.people.workdayPersonProfile"
}

locals {
  kafka_producer_secrets  = jsondecode(data.aws_secretsmanager_secret_version.kafka_producer.secret_string)
  schema_registry_secrets = jsondecode(data.aws_secretsmanager_secret_version.schema_registry.secret_string)
}
