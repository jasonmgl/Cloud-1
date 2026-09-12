# This is entirely skipped when no domain is configured (When count is 0)

data "cloudflare_zone" "this" {
  count = var.domain_name != "" ? 1 : 0
  filter = {
    name = var.cloudflare_zone_name
  }
}

resource "cloudflare_dns_record" "this" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = data.cloudflare_zone.this[0].zone_id
  name    = var.domain_name
  type    = "A"
  content = aws_eip.instances[var.dns_target_instance].public_ip
  ttl     = 1     # auto
  proxied = false # DNS only
}
