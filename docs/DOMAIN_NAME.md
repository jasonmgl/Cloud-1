# Using a domain name

This project's TLS automation is built specifically for [**Cloudflare**](https://www.cloudflare.com/) **DNS**. Using a domain managed elsewhere requires changes to the `tls` role.

By default `domain_name` can be a bare IP address, which gets a self-signed certificate automatically. 　　
To use a real Cloudflare-managed domain with a trusted TLS certificate instead:

1. Point a DNS `A record` at the server's IP in Cloudflare: add the record as **DNS only** (grey cloud icon), not proxied. Proxying would terminate TLS at Cloudflare's edge instead of this project's server. (Handled by Terraform in this project)
2. Create a Cloudflare API token with `Zone:DNS:Edit` permission for that zone. Only DNS record management is needed for the DNS-01 challenge.
3. Set `domain_name` and `cloudflare_zone_name` in `terraform/terraform.tfvars`.
4. Add the token as `vault_dns_api_token` in `ansible/group_vars/all/vault.yaml`. See [`VAULT.md`](./VAULT.md) to know how to edit.
5. The ansible `tls` role detects that `domain_name` isn't an IP address and requests a certificate from Let's Encrypt via a Cloudflare DNS-01 challenge instead of generating a self-signed one.

If we switch `domain_name` after already deploying once, note that WordPress's site URL is baked into the database from the first install and won't update on its own. 

> [!TIP]
> The domain must be added to Cloudflare before using it in this project.
>
> - If you don't have a domain yet, register one directly through [Cloudflare Registrar](https://developers.cloudflare.com/registrar/get-started/register-domain/): it automatically uses Cloudflare's nameservers, so no further nameserver setup is needed.
> - If you already own a domain registered elsewhere, [add it to Cloudflare](https://developers.cloudflare.com/fundamentals/manage-domains/add-site/) as a site, then set the two nameservers Cloudflare assigns at your original registrar. This can take anywhere from a few minutes to 24 hours to propagate.
>
> Either way, the zone must show as "Active" in the Cloudflare dashboard before the steps above (API token, `domain_name`, `cloudflare_zone_name`) will work.
