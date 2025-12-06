# terraform/tfvars/prod/prod1.tfvars

department = "paf"
region     = "us-west-2"

# Update with actual Production private subnet IDs
private_subnet_ids = [
  "subnet-xxxxxxxxxxxxxxxxx", # paf-prod-prod1-calm-private-subnet-0 (us-west-2a)
  "subnet-xxxxxxxxxxxxxxxxx", # paf-prod-prod1-calm-private-subnet-1 (us-west-2b)
  "subnet-xxxxxxxxxxxxxxxxx"  # paf-prod-prod1-calm-private-subnet-2 (us-west-2c)
]

kafka_bootstrap = "lkc-w79n05-6n41wp.us-west-2.aws.glb.confluent.cloud:9092"
