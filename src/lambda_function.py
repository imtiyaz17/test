import json
import logging
import os
import time

import boto3
import swacerts

from confluent_kafka import Producer
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer
from confluent_kafka.serialization import MessageField, SerializationContext, StringSerializer

# Structured logging
log = logging.getLogger()
log.setLevel(logging.INFO)

# CloudWatch client for custom metrics
cloudwatch = boto3.client("cloudwatch")

# --------- Environment variables ----------
BOOTSTRAP = os.environ["KAFKA_BOOTSTRAP"]
API_KEY = os.environ["KAFKA_API_KEY"]
API_SECRET = os.environ["KAFKA_API_SECRET"]
TOPIC = os.environ.get("KAFKA_TOPIC", "int.people.workdayPersonProfile.v1")

SR_URL = os.environ["SCHEMA_REGISTRY_URL"]
SR_KEY = os.environ["SCHEMA_REGISTRY_API_KEY"]
SR_SECRET = os.environ["SCHEMA_REGISTRY_API_SECRET"]

NAMESPACE = os.getenv("NAMESPACE", "dev")

# --------- Avro schema (value schema) ----------
AVRO_SCHEMA_STR = """
{
  "type": "record",
  "name": "WorkdayLeaveEnvelope",
  "namespace": "com.company.hr.workday",
  "doc": "Workday leave of absence events as delivered from Workday",
  "fields": [
    {
      "name": "Data",
      "type": {
        "type": "array",
        "items": {
          "name": "WorkdayLeaveRecord",
          "type": "record",
          "fields": [
            { "name": "Worker_Type", "type": "string" },
            { "name": "Worker_personnelNumber", "type": "string" },
            { "name": "Worker_userID", "type": "string" },
            { "name": "Worker_personnelStatusCode", "type": "string" },
            {
              "name": "Leave",
              "type": {
                "name": "WorkdayLeave",
                "type": "record",
                "fields": [
                  { "name": "EventWID", "type": ["null", "string"], "default": null },
                  { "name": "Operation", "type": "string" },
                  { "name": "Type", "type": ["null", "string"], "default": null },
                  { "name": "OnLeave", "type": ["null", "boolean"], "default": null },
                  { "name": "LeaveStartDate", "type": ["null", "string"], "default": null },
                  { "name": "EstimatedLeaveEndDate", "type": ["null", "string"], "default": null },
                  { "name": "LeaveEndDate", "type": ["null", "string"], "default": null },
                  { "name": "FirstDayOfWork", "type": ["null", "string"], "default": null },
                  { "name": "LeaveLastDayOfWork", "type": ["null", "string"], "default": null },
                  { "name": "LeaveOfAbsenceType", "type": ["null", "string"], "default": null },
                  { "name": "LeaveOfAbsenceTypeDescription", "type": ["null", "string"], "default": null },
                  { "name": "CaseNumber", "type": ["null", "string"], "default": null },
                  { "name": "FrequencyAndDuration", "type": ["null", "string"], "default": null },
                  { "name": "ExpectedDueDate", "type": ["null", "string"], "default": null },
                  { "name": "CeasareanSectionBirth", "type": ["null", "string"], "default": null },
                  { "name": "DateOfInjury", "type": ["null", "string"], "default": null },
                  { "name": "ChildBirthDate", "type": ["null", "string"], "default": null }
                ]
              }
            }
          ]
        }
      }
    }
  ]
}
"""


def error_cb(err):
    log.error(json.dumps({"event": "kafka_error", "error": str(err)}))


# --------- Kafka & Schema Registry clients ----------
producer_conf = {
    "bootstrap.servers": BOOTSTRAP,
    "security.protocol": "SASL_SSL",
    "sasl.mechanisms": "PLAIN",
    "sasl.username": API_KEY,
    "sasl.password": API_SECRET,
    "linger.ms": 5,
    "batch.num.messages": 1000,
    "error_cb": error_cb,
}
CERTS = swacerts.where()
_sr_client = SchemaRegistryClient(
    {"url": SR_URL, "ssl.ca.location": CERTS, "basic.auth.user.info": f"{SR_KEY}:{SR_SECRET}"}
)
_value_serializer = AvroSerializer(
    schema_registry_client=_sr_client,
    schema_str=AVRO_SCHEMA_STR,
    to_dict=lambda obj, ctx: obj,
)
_key_serializer = StringSerializer("utf_8")
_producer = Producer(producer_conf)


def _delivery_cb(err, msg):
    if err:
        log.error(json.dumps({"event": "delivery_failed", "error": str(err)}))
    else:
        log.info(
            json.dumps(
                {
                    "event": "delivery_success",
                    "topic": msg.topic(),
                    "partition": msg.partition(),
                    "offset": msg.offset(),
                }
            )
        )


def _publish_metric(metric_name, value, unit="Count"):
    """Publish custom metric to CloudWatch."""
    function_name = os.environ.get("AWS_LAMBDA_FUNCTION_NAME", "unknown")
    try:
        cloudwatch.put_metric_data(
            Namespace=f"CALM/{function_name}",
            MetricData=[
                {
                    "MetricName": metric_name,
                    "Value": value,
                    "Unit": unit,
                    "Dimensions": [
                        {"Name": "Environment", "Value": NAMESPACE},
                    ],
                }
            ],
        )
    except Exception as e:
        log.warning(json.dumps({"event": "metric_publish_failed", "error": str(e)}))


def transform_payload(payload):
    """Convert empty strings to None for nullable fields."""
    if "Data" in payload:
        for worker_data in payload["Data"]:
            if "Leave" in worker_data:
                leave = worker_data["Leave"]
                for field in leave:
                    if leave[field] == "":
                        leave[field] = None
    return payload


def lambda_handler(event, context):
    start_time = time.time()
    request_id = context.aws_request_id
    event_wid = None

    try:
        # Structured log - no PII, only metadata
        log.info(
            json.dumps(
                {
                    "event": "request_received",
                    "request_id": request_id,
                    "source": "api_gateway" if "body" in event else "direct_invocation",
                }
            )
        )

        # Handle both API Gateway and direct invocation
        payload = json.loads(event["body"]) if "body" in event else event

        # Validate required Data field
        if "Data" not in payload or not payload["Data"]:
            raise ValueError("Missing required 'Data' field in payload")

        # Extract key from nested structure
        event_wid = payload.get("Data", [{}])[0].get("Leave", {}).get("EventWID", "unknown")
        key = event_wid or "unknown"

        # Transform payload
        transformed_payload = transform_payload(payload)

        log.info(
            json.dumps(
                {
                    "event": "producing_message",
                    "request_id": request_id,
                    "event_wid": event_wid,
                    "topic": TOPIC,
                }
            )
        )

        _producer.produce(
            topic=TOPIC,
            key=_key_serializer(key),
            value=_value_serializer(
                transformed_payload, SerializationContext(TOPIC, MessageField.VALUE)
            ),
            on_delivery=_delivery_cb,
        )

        # Track Kafka write time separately
        kafka_start = time.time()
        _producer.poll(0)
        remaining = _producer.flush(10)
        kafka_duration = time.time() - kafka_start

        if remaining > 0:
            raise Exception(f"Kafka flush timeout: {remaining} messages not delivered")

        # Success metrics
        total_duration = time.time() - start_time
        _publish_metric("MessageProduced", 1)
        _publish_metric("ProcessingDuration", total_duration * 1000, "Milliseconds")
        _publish_metric("KafkaWriteDuration", kafka_duration * 1000, "Milliseconds")

        log.info(
            json.dumps(
                {
                    "event": "message_produced",
                    "request_id": request_id,
                    "event_wid": event_wid,
                    "duration_ms": round(total_duration * 1000, 2),
                    "kafka_write_ms": round(kafka_duration * 1000, 2),
                }
            )
        )

        # Return response for API Gateway
        if "body" in event:
            return {
                "statusCode": 202,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"status": "accepted"}),
            }

    except Exception as e:
        duration = time.time() - start_time
        _publish_metric("MessageFailed", 1)

        log.error(
            json.dumps(
                {
                    "event": "processing_failed",
                    "request_id": request_id,
                    "event_wid": event_wid,
                    "error": str(e),
                    "duration_ms": round(duration * 1000, 2),
                }
            )
        )
        raise
