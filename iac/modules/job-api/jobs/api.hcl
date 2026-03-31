job "api" {
  node_pool = "${node_pool}"
  priority = 90

  group "api-service" {
    count = ${count}

    restart {
      interval = "5s"
      attempts = 1
      delay    = "5s"
      mode     = "delay"
    }

    network {
      port "api" { static = "${port_number}" }
      port "grpc" { static = "${api_grpc_port}" }
%{ if prevent_colocation }
      port "scheduling-block" {
        static = 40234
      }
%{ endif }
    }

    constraint {
      operator = "distinct_hosts"
      value    = "true"
    }

    service {
      name = "api"
      port = "${port_number}"
      task = "start"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.api.rule=HostRegexp(`api.{domain:.+}`)",
        "traefik.http.routers.api.ruleSyntax=v2",
        "traefik.http.routers.api.priority=500",
      ]

      check {
        type     = "http"
        name     = "health"
        path     = "/health"
        interval = "3s"
        timeout  = "3s"
        port     = "${port_number}"
      }
    }

    service {
      name = "api-grpc"
      port = "grpc"
      task = "start"

      check {
        type     = "tcp"
        name     = "grpc"
        interval = "3s"
        timeout  = "3s"
        port     = "grpc"
      }
    }

%{ if update_stanza }
    update {
      max_parallel      = 1
      canary            = 1
      min_healthy_time  = "10s"
      healthy_deadline  = "10800s"
      progress_deadline = "10801s"
      auto_promote      = true
      auto_revert       = true
    }
%{ endif }

    task "start" {
      driver       = "docker"
      kill_timeout = "30s"
      kill_signal  = "SIGTERM"

      resources {
        memory_max = ${memory_mb * 2}
        memory     = ${memory_mb}
        cpu        = ${cpu_count * 1000}
      }

      env {
        ENVIRONMENT                    = "${environment}"
        DOMAIN_NAME                    = "${domain_name}"
        NODE_ID                        = "$${node.unique.id}"
        NOMAD_TOKEN                    = "${nomad_acl_token}"
        ORCHESTRATOR_PORT              = "${orchestrator_port}"
        API_GRPC_PORT                  = "${api_grpc_port}"
        ADMIN_TOKEN                    = "${admin_token}"
        SANDBOX_ACCESS_TOKEN_HASH_SEED = "${sandbox_access_token_hash_seed}"
        POSTGRES_CONNECTION_STRING              = "${postgres_connection_string}"
        DB_MAX_OPEN_CONNECTIONS                = "${db_max_open_connections}"
        DB_MIN_IDLE_CONNECTIONS                = "${db_min_idle_connections}"
        AUTH_DB_CONNECTION_STRING              = "${postgres_connection_string}"
        AUTH_DB_READ_REPLICA_CONNECTION_STRING = "${postgres_read_replica_connection_string}"
        AUTH_DB_MAX_OPEN_CONNECTIONS           = "${auth_db_max_open_connections}"
        AUTH_DB_MIN_IDLE_CONNECTIONS           = "${auth_db_min_idle_connections}"
        REDIS_POOL_SIZE                        = "${redis_pool_size}"
        REDIS_CLUSTER_URL                      = "${redis_cluster_url}"
        REDIS_TLS_CA_BASE64                    = "${redis_tls_ca_base64}"
        REDIS_URL                              = "${redis_url}"
        SANDBOX_STORAGE_BACKEND                = "${sandbox_storage_backend}"
        TEMPLATE_BUCKET_NAME                   = "skip"
%{ for key, value in job_env_vars }
  %{ if value != "" }
        ${key} = "${value}"
  %{ endif }
%{ endfor }
      }

      config {
        network_mode = "host"
        image        = "${api_docker_image}"
        ports        = ["${port_name}"]
        args         = ["--port", "${port_number}"]
      }
    }

    task "db-migrator" {
      driver = "docker"

      env {
        POSTGRES_CONNECTION_STRING = "${postgres_connection_string}"
      }

      config {
        image = "${db_migrator_docker_image}"
      }

      resources {
        cpu    = 250
        memory = 128
      }

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }
    }
  }
}
