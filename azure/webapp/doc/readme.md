# Azure Design

## Service Comparisons

| Tier           | Azure Service                 |
| -------------- | ----------------------------- |
| Edge           | Application Gateway WAF       |
| Web            | VM Scale Set or AKS           |
| API            | Internal AKS services         |
| Database       | PostgreSQL Flexible Server HA |
| Secrets        | Key Vault                     |
| Monitoring     | Azure Monitor + Log Analytics |
| IAM            | Managed Identity              |
| Outbound       | NAT Gateway                   |
| Private Access | Private Endpoints             |

## Compute Layer

### Web Tier

- Behind an `Application Gateway`:
  - Virtual Machine Scale Set (VMSS)
    - Similar to `AWS Auto Scaling Groups`
  - Azure Kubernetes Service (AKS)
  - App Service
  - Container Apps
- Web Application Firewall (WAF)
  - Equivalent to `AWS Application Load Balancer (ALB) and (Web Application Firewall) WAF`

### API Tier

- Internal Load Balancer
- VMSS / AKS / Container Apps

## Azure Specifics

### Web Application Firewall (WAF)

- Features
  - Managed Rule Sets
  - Bot Protection
  - Custom Rules
  - Detection & Prevention Modes
- Where It Can Be Deployed
  - Azure Application Gateway
  - Azure Front Door

### Networking Nuance

- Unlike `AWS`, `Azure NSG`'s are usually _subnet-based, CIDR-based_ rather than `SG-to-SG` reference
- `Azure` does support `Application Security Group`'s (ASGs) which are conceptually similar to `AWS SG` references
- Large production environments prefer `ASG` over raw `CIDR`s

### Costs

- `Azure NAT Gateway`:
  - Generally cheaper than multiple `AWS NAT Gateway`s
- `Application Gateway WAF`
  - Can become expensive under load
- `Azure PostgreSQL Flexible Server`
  - `HA` costs rise significantly with zone redundancy

## Initial Directory Structure

terraform/
├── providers.tf
├── variables.tf
├── main.tf
├── networking.tf
├── security.tf
├── compute.tf
├── database.tf
├── outputs.tf
└── terraform.tfvars
