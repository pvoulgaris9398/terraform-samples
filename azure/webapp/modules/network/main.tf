locals {
  subnet_instances = flatten([
    for subnet_key, subnet_def in var.subnets : [
      for az_index in range(var.az_count) : {
        key            = "${subnet_key}-${az_index}"
        name           = "${var.name_prefix}-${subnet_key}-subnet-${az_index}"
        type           = subnet_key
        address_prefix = cidrsubnet(var.vnet_cidr, var.address_prefix_length, subnet_def.address_prefix_offset + az_index)
        delegation     = lookup(subnet_def, "service_delegation", null)
      }
    ]
  ])

  subnet_map = { for subnet in local.subnet_instances : subnet.key => subnet }

  subnet_ids_by_type = {
    for subnet_type in keys(var.subnets) :
    subnet_type => [
      for subnet in azurerm_subnet.main : subnet.value.id if subnet.value.type == subnet_type
    ]
  }

  subnet_prefixes_by_type = {
    for subnet_type in keys(var.subnets) :
    subnet_type => [
      for subnet in azurerm_subnet.main : subnet.value.address_prefixes[0] if subnet.value.type == subnet_type
    ]
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.name_prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "main" {
  for_each = local.subnet_map

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.address_prefix]

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.name
        actions = delegation.value.actions
      }
    }
  }
}

resource "azurerm_public_ip" "nat" {
  name                = "${var.name_prefix}-nat-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "main" {
  name                = "${var.name_prefix}-nat-gateway"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "main" {
  for_each = {
    for key, subnet in azurerm_subnet.main : key => subnet
    if contains(["api", "db"], subnet.type)
  }

  subnet_id      = each.value.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}
