job "client-proxy" {
  node_pool = "${node_pool}"
  priority  = 80

  group "client-proxy" {
    restart {
      attempts = 2
      interval = "10m"
      delay    = "10s"
      mode     = "fail"
    }

    reschedule {
      delay          = "30s"
      delay_function = "exponential"
      max_delay      = "10m"
      unlimited      = true
    }

    count = ${count}

    constraint {
      operator  = "distinct_hosts"
      value     = "true"
    }

    network {
      port "proxy" { static = "${proxy_port}" }
      port "health" { static = "${health_port}" }
    }

    service {
      name = "client-proxy"
      port = "proxy"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.client-proxy.rule=PathPrefix(`/`)",
        "traefik.http.routers.client-proxy.ruleSyntax=v2",
        "traefik.http.routers.client-proxy.priority=100",
        "traefik.http.services.client-proxy.loadbalancer.server.port=$${NOMAD_PORT_proxy}",
      ]

      check {
        type     = "http"
        name     = "health"
        path     = "/health"
        interval = "3s"
        timeout  = "3s"
        port     = "health"
      }
    }

%{ if update_stanza }
    update {
      max_parallel      = ${update_max_parallel}
      canary            = ${update_max_parallel}
      min_healthy_time  = "10s"
      healthy_deadline  = "30s"
      auto_promote      = true
      progress_deadline = "24h"
    }
%{ endif }

    task "start" {
      driver = "docker"
%{ if update_stanza }
      kill_timeout = "24h"
%{ endif }
      kill_signal = "SIGTERM"

      resources {
        memory_max = ${memory_mb * 1.5}
        memory     = ${memory_mb}
        cpu        = ${cpu_count * 1000}
      }

      env {
        NODE_ID     = "$${node.unique.id}"
        NODE_IP     = "$${attr.unique.network.ip-address}"
        HEALTH_PORT = "$${NOMAD_PORT_health}"
        PROXY_PORT  = "$${NOMAD_PORT_proxy}"
        ENVIRONMENT = "${environment}"
        REDIS_POOL_SIZE     = "${redis_pool_size}"
        REDIS_CLUSTER_URL   = "${redis_cluster_url}"
        REDIS_TLS_CA_BASE64 = "${redis_tls_ca_base64}"
        REDIS_URL           = "${redis_url}"

%{ if api_grpc_address != "" }
        API_GRPC_ADDRESS = "${api_grpc_address}"
%{ endif }
      }

      config {
        network_mode = "host"
        image        = "${image}"
        ports        = ["proxy", "health"]
      }
    }
  }
}
