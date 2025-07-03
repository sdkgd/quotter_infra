resource "aws_service_discovery_private_dns_namespace" "local" {
  name        = "local"
  description = "Private namespace"
  vpc         = aws_vpc.this.id
}

locals {
  services = ["web", "php", "next"]
}

resource "aws_service_discovery_service" "services" {
  for_each = toset(local.services)

  name = each.key

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.local.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}