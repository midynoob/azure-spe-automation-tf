# Create resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create resource group for automation
resource "azurerm_resource_group" "automation_rg" {
  name     = "${var.resource_group_name}-automation"
  location = var.location
}

# Create Azure Automation Account
resource "azurerm_automation_account" "automation" {
  name                = var.automation_account_name
  location            = azurerm_resource_group.automation_rg.location
  resource_group_name = azurerm_resource_group.automation_rg.name
  sku_name           = "Basic"
}

# Create Service Principal
resource "azuread_application" "app" {
  display_name = var.service_principal_name
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
    resource_access {
      id   = "7ab1d382-f21e-4acd-a863-ba3e13f7da61" # Directory.Read.All
      type = "Role"
    }
    resource_access {
      id   = "06da0dbc-49e2-44d2-8312-53f166ab848a" # Application.Read.All
      type = "Role"
    }
    resource_access {
      id   = "e383f46e-2787-4529-855e-0e479a3ffac0" # Mail.Send
      type = "Role"
    }
  }
}
resource "azuread_service_principal" "sp" {
  client_id = azuread_application.app.application_id
}

# Create Service Principal password
resource "azuread_service_principal_password" "sp_password" {
  service_principal_id = azuread_service_principal.sp.id
}

# Create Automation Variable for Service Principal details
resource "azurerm_automation_variable_string" "sp_client_id" {
  name                    = "ServicePrincipalClientId"
  resource_group_name     = azurerm_resource_group.automation_rg.name
  automation_account_name = azurerm_automation_account.automation.name
  value                   = azuread_application.app.application_id
}

resource "azurerm_automation_variable_string" "sp_client_secret" {
  name                    = "ServicePrincipalClientSecret"
  resource_group_name     = azurerm_resource_group.automation_rg.name
  automation_account_name = azurerm_automation_account.automation.name
  value                   = azuread_service_principal_password.sp_password.value
}

resource "azurerm_automation_variable_string" "sp_tenant_id" {
  name                    = "ServicePrincipalTenantId"
  resource_group_name     = azurerm_resource_group.automation_rg.name
  automation_account_name = azurerm_automation_account.automation.name
  value                   = var.tenant_id
}

# Create PowerShell Runbook
resource "azurerm_automation_runbook" "sp_expiry_check" {
  name                    = "CheckServicePrincipalExpiry"
  location                = azurerm_resource_group.automation_rg.location
  resource_group_name     = azurerm_resource_group.automation_rg.name
  automation_account_name = azurerm_automation_account.automation.name
  log_verbose            = "true"
  log_progress           = "true"
  description            = "Checks for service principals expiring in the next 30 days"
  runbook_type           = "PowerShell"

  content = <<CONTENT
param(
    [string]$ClientId = $null,
    [string]$ClientSecret = $null,
    [string]$TenantId = $null
)

# Connect to Azure using service principal
$secureSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($ClientId, $secureSecret)
Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $TenantId

# Get all service principals
$servicePrincipals = Get-AzADServicePrincipal

# Get current date and date 30 days from now
$currentDate = Get-Date
$futureDate = $currentDate.AddDays(30)

# Filter service principals expiring in next 30 days
$expiringSPs = $servicePrincipals | Where-Object {
    $_.EndDate -and $_.EndDate -gt $currentDate -and $_.EndDate -lt $futureDate
}

# Output results
Write-Output "Service Principals expiring in the next 30 days:"
$expiringSPs | ForEach-Object {
    Write-Output "DisplayName: $($_.DisplayName)"
    Write-Output "ApplicationId: $($_.ApplicationId)"
    Write-Output "Expiry Date: $($_.EndDate)"
    Write-Output "-------------------"
}
CONTENT
} 