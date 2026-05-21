locals {
  nsg_definitions = {
    web = {
      name = "${var.name_prefix}-web-nsg"
      rules = [
        {
          name                       = "allow-http"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "allow-https"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }
    api = {
      name = "${var.name_prefix}-api-nsg"
      rules = [
        {
          name                       = "allow-web-to-api"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_address_prefixes    = var.subnet_prefixes.web
          source_port_range          = "*"
          destination_port_range     = "8080"
          destination_address_prefix = "*"
        }
      ]
    }
    db = {
      name = "${var.name_prefix}-db-nsg"
      rules = [
        {
          name                       = "allow-api-to-db"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_address_prefixes    = var.subnet_prefixes.api
          source_port_range          = "*"
          destination_port_range     = "5432"
          destination_address_prefix = "*"
        }
      ]
    }
  }

  subnet_associations = flatten([
    for subnet_type, ids in var.subnet_ids : [
      for id in ids : {
        key         = "${subnet_type}-${id}"
        subnet_type = subnet_type
        subnet_id   = id
      }
    ]
  ])

  associations = {
    for assoc in local.subnet_associations : assoc.key => assoc
  }
}

resource "azurerm_network_security_group" "main" {
  for_each = local.nsg_definitions

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  dynamic "security_rule" {
    for_each = each.value.rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      destination_address_prefix = security_rule.value.destination_address_prefix
      source_address_prefix      = lookup(security_rule.value, "source_address_prefix", null)
      source_address_prefixes    = lookup(security_rule.value, "source_address_prefixes", null)
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = local.associations

  subnet_id                 = each.value.subnet_id
  network_security_group_id = azurerm_network_security_group.main[each.value.subnet_type].id
}
