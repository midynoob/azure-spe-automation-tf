# Azure Service Principal Expiry Check Automation

This Terraform project creates an Azure Automation solution to monitor service principal expirations. It includes:

1. A service principal with required permissions (Application.Read.All, Directory.Read.All, Mail.Send)
2. An Azure Automation account with variables storing the service principal details
3. A PowerShell runbook that checks for service principals expiring in the next 30 days

## Prerequisites

- Azure CLI installed and configured
- Terraform installed
- Appropriate permissions in Azure AD to create service principals and assign permissions

## Usage

1. Initialize Terraform:
```bash
terraform init
```

2. Create a `terraform.tfvars` file with the following variables:
```hcl
resource_group_name     = "your-resource-group-name"
location               = "eastus"
automation_account_name = "your-automation-account-name"
service_principal_name  = "your-service-principal-name"
subscription_id        = "your-subscription-id"
tenant_id             = "your-tenant-id"
```

3. Apply the Terraform configuration:
```bash
terraform apply
```

4. After successful deployment, you can find the following outputs:
   - Automation Account Name
   - Service Principal Client ID
   - Service Principal Client Secret (sensitive)
   - Runbook Name

## Runbook Usage

The created runbook can be executed manually or scheduled to run automatically. It will:
1. Connect to Azure using the service principal credentials
2. Retrieve all service principals
3. Filter for those expiring in the next 30 days
4. Output the results with display name, application ID, and expiry date

## Security Notes

- The service principal client secret is stored as a sensitive variable in Azure Automation
- Make sure to properly secure the `terraform.tfvars` file as it contains sensitive information
- Consider using Azure Key Vault for storing sensitive values in production environments