# terraform/tfvars/dev/dev1-us-west-2.tfvars

department = "paf"
region     = "us-west-2"

vpc_id = "vpc-0dcc89deae7280ef5"

private_subnet_ids = [
  "subnet-0b4b37e9cc4fa0ff7", # paf-dev-dev1-calm-private-subnet-0 (us-west-2a)
  "subnet-070d59471d7caa217", # paf-dev-dev1-calm-private-subnet-1 (us-west-2b)
  "subnet-060908935d0c48bb0"  # paf-dev-dev1-calm-private-subnet-2 (us-west-2c)
]

kafka_bootstrap = "lkc-gqdodv-pyor4g.us-west-2.aws.glb.confluent.cloud:9092"
