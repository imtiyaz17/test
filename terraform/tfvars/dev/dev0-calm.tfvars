# terraform/tfvars/dev/dev0.tfvars

department = "paf"
region     = "us-east-1"

vpc_id = "vpc-00133dbd77c06a4de"

private_subnet_ids = [
  "subnet-07f010c6a2e5d7f12", # paf-dev-dev0-calm-private-subnet-0 (us-east-1a)
  "subnet-05d13464b47f103d5", # paf-dev-dev0-calm-private-subnet-1 (us-east-1b)
  "subnet-02f76b10a609f988b"  # paf-dev-dev0-calm-private-subnet-2 (us-east-1c)
]

kafka_bootstrap = "lkc-pgd2d2-g4mv3g.us-east-1.aws.glb.confluent.cloud:9092"
