resource "azurerm_container_app" "this" {
  name                         = "${var.prefix}-${var.name}"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = var.revision_mode
  tags                         = var.tags

  template {
    container {
      name   = var.container_name
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.environment_variables
        content {
          name        = env.key
          secret_name = env.value
        }
      }
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas
  }

  ingress {
    external_enabled = var.ingress_enabled
    target_port      = var.target_port

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  secret {
    name  = var.secret_name
    value = var.secret_value
  }
}
