locals {
  nomad_server_count = 3
}

resource "vultr_reserved_ip" "nomad_server_one" {
  # $0.004/hour ($3/month)
  ip_type = "v4"
  region  = "ams"
}

# Create a nomad node
resource "vultr_instance" "nomad_server" {
  # $20/month
  # 2 vCPU 4GB
  plan = "vc2-2c-4gb"
  # Amsterdam
  region = "ams"
  # Debian 12 x64 (bookworm)
  os_id = 2136

  count = local.nomad_server_count

  hostname = "nomad-server-${count.index}"

  reserved_ip_id = count.index == 0 ? vultr_reserved_ip.nomad_server_one.id : null

  user_data = data.template_cloudinit_config.nomad.rendered
}

# Render a part using a `template_file`
data "template_file" "script" {
  template = file("${path.module}/cloud-config.yaml")

  vars = {
    server_count    = local.nomad_server_count
    first_server_ip = vultr_reserved_ip.nomad_server_one.subnet
  }
}

data "template_cloudinit_config" "nomad" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/jinja2"

    content = data.template_file.script.rendered

  }

}


# Output the IPs of the Nomad servers

output "nomad_server_ips" {
  value = vultr_instance.nomad_server[*].main_ip
}



resource "local_file" "postfix_config" {
  filename = "hosts.txt"
  content  = <<-EOT
  ${join("\n", vultr_instance.nomad_server[*].main_ip)}
  EOT
}

# Register some DNS records

resource "vultr_dns_domain" "whoami_domain" {
  # this should be whoami.brodul.org, but Vultr does not like burek
  domain = "brodul.org"
  ip     = vultr_reserved_ip.nomad_server_one.subnet
}

resource "vultr_dns_record" "whoami_server" {
  count  = local.nomad_server_count
  domain = vultr_dns_domain.whoami_domain.id
  # should be server-${count.index + 1} but Vultr 
  name = "server${count.index + 1}.whoami"
  type = "A"
  data = vultr_instance.nomad_server[count.index].main_ip
}
