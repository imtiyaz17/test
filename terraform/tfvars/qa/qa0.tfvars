# terraform/tfvars/qa/qa0.tfvars

department = "paf"
region     = "us-east-1"

# Update with actual QA private subnet IDs
private_subnet_ids = [
  "subnet-xxxxxxxxxxxxxxxxx", # paf-qa-qa0-calm-private-subnet-0 (us-east-1a)
  "subnet-xxxxxxxxxxxxxxxxx", # paf-qa-qa0-calm-private-subnet-1 (us-east-1b)
  "subnet-xxxxxxxxxxxxxxxxx"  # paf-qa-qa0-calm-private-subnet-2 (us-east-1c)
]

kafka_bootstrap = "lkc-12pnv5-6klyqg.us-east-1.aws.glb.confluent.cloud:9092"
