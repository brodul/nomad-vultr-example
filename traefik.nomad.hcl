job "traefik-system" {
  datacenters = ["dc1"]
  type        = "system"

  group "traefik" {
    count = 1

    network {
      port  "http"{
         static = 80
      }
      port  "admin"{
         static = 8080
      }
    }

    service {
      name = "traefik-http"
      provider = "nomad"
      port = "http"
    }

    service {
      name = "traefik-admin"
      provider = "nomad"
      port = "admin"
    }

    task "server" {
      driver = "docker"

      config {
        image = "traefik"
        ports = ["admin", "http"]
        args = [
          "--configFile=${NOMAD_ALLOC_DIR}/data/traefik/traefik.yml"
        ]
      }
      template {
       data = <<EOH
{{ with nomadVar "nomad/jobs/traefik-system/traefik/server" }}
providers:
  nomad:
    endpoint:
      address: {{ .address }}
      token: {{ .token }}
log:
  level: debug
api:
  insecure: true
  dashboard: true
entryPoints:
  web:
    address: :{{ env "NOMAD_PORT_http" }}
  traefik:
    address: :{{ env "NOMAD_PORT_admin" }}
{{ end }}
EOH

      destination = "${NOMAD_ALLOC_DIR}/data/traefik/traefik.yml"
      change_mode = "restart"
      }        
    }
  }
}