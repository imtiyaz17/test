# terraform/tfvars/prod/prod0.tfvars

department = "paf"
region     = "us-east-1"

# Update with actual Production private subnet IDs
private_subnet_ids = [
  "subnet-xxxxxxxxxxxxxxxxx", # paf-prod-prod0-calm-private-subnet-0 (us-east-1a)
  "subnet-xxxxxxxxxxxxxxxxx", # paf-prod-prod0-calm-private-subnet-1 (us-east-1b)
  "subnet-xxxxxxxxxxxxxxxxx"  # paf-prod-prod0-calm-private-subnet-2 (us-east-1c)
]

kafka_bootstrap = "lkc-k8592g-pryzd6.us-east-1.aws.glb.confluent.cloud:9092"
