# Azure Container Sample with SignalR

- Running in `Azure App Management`

## Working Log

### `Saturday, 5/30/2026`

- When deploying the current state of Infrastructure in terraform, I encountered:

![](2026-05-30-01.jpg)

```text
│ Error: creating Signal R (Subscription: "xxxxxxxx-yyyy-zzzz-aaaa-bbbbbbbbbbbb"
│ Resource Group Name: "rg-realtime-dashboard"
│ Signal R Name: "realtimedemo-signalr"): performing CreateOrUpdate: unexpected status 400 (400 Bad Request) with error: BadArgument: Leaf domain realtimedemo-signalr is already in use. Please use a different resource name.
│
│   with module.signalr_service.azurerm_signalr_service.this,
│   on modules\signalr_service\main.tf line 1, in resource "azurerm_signalr_service" "this":
│    1: resource "azurerm_signalr_service" "this" {

```

- This was due to non-unique resource names, added a unique/random string suffix where needed to get past this