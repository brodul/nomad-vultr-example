job "whoami" {
  datacenters = ["dc1"]

  type = "service"

  group "demo" {
    count = 1

    network {
       port "http" {
         to = 80
       }
    }

    service {
      name = "whoami-demo"
      port = "http"
      provider = "nomad"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.http.rule=Host(`server1.whoami.brodul.org`) || Host(`server2.whoami.brodul.org`) || Host(`server3.whoami.brodul.org`)",
      ]
    }

    task "server" {
      env {
        WHOAMI_PORT_NUMBER = "${NOMAD_PORT_http}"
      }

      driver = "docker"

      config {
        image = "traefik/whoami"
        ports = ["http"]
      }
    }
  }
}