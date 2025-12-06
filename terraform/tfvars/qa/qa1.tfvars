# terraform/tfvars/qa/qa1.tfvars

department = "paf"
region     = "us-west-2"

# Update with actual QA private subnet IDs
private_subnet_ids = [
  "subnet-xxxxxxxxxxxxxxxxx", # paf-qa-qa1-calm-private-subnet-0 (us-west-2a)
  "subnet-xxxxxxxxxxxxxxxxx", # paf-qa-qa1-calm-private-subnet-1 (us-west-2b)
  "subnet-xxxxxxxxxxxxxxxxx"  # paf-qa-qa1-calm-private-subnet-2 (us-west-2c)
]

kafka_bootstrap = "lkc-gqo9v3-gemw96.us-west-2.aws.glb.confluent.cloud:9092"
