output "automation_resource_group_name" {
  value = azurerm_resource_group.automation_rg.name
}

output "automation_account_name" {
  value = azurerm_automation_account.automation.name
}

output "service_principal_client_id" {
  value = azuread_application.app.application_id
}

output "service_principal_client_secret" {
  value     = azuread_service_principal_password.sp_password.value
  sensitive = true
}

output "runbook_name" {
  value = azurerm_automation_runbook.sp_expiry_check.name
} 