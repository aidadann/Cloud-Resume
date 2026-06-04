resource "azurerm_resource_group" "rg" {
  name     = "rg-cloudresume-iac" # Give it a new name so it doesn't clash with your ClickOps one
  location = "Southeast Asia"            # Change to your preferred region
}

resource "azurerm_storage_account" "frontend" {
  name                     = "stcloudresumeaidaniac" # Must be globally unique, lowercase only
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Monitoring: Log Analytics & Application Insights
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-cloudresume"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
}

resource "azurerm_application_insights" "app_insights" {
  name                = "appi-cloudresume"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.law.id
}

# Database: Cosmos DB Serverless Account
resource "azurerm_cosmosdb_account" "db_account" {
  name                = "cosmos-cloudresume-aidan1911" # MUST BE GLOBALLY UNIQUE
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
}

# Database: Cosmos DB SQL Database and Container
resource "azurerm_cosmosdb_sql_database" "db" {
  name                = "ResumeDB"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.db_account.name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  name                  = "Counter"
  resource_group_name   = azurerm_resource_group.rg.name
  account_name          = azurerm_cosmosdb_account.db_account.name
  database_name         = azurerm_cosmosdb_sql_database.db.name
  partition_key_paths   = ["/id"]
}

# Compute: Service Plan (Consumption Tier for Serverless)
resource "azurerm_service_plan" "asp" {
  name                = "asp-cloudresume"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

# Compute: Python Azure Function App
resource "azurerm_linux_function_app" "function_app" {
  name                       = "func-cloudresume-aidan1911" # MUST BE GLOBALLY UNIQUE
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.asp.id
  
  # Functions need a storage account for internal operations
  storage_account_name       = azurerm_storage_account.frontend.name
  storage_account_access_key = azurerm_storage_account.frontend.primary_access_key

  site_config {
    application_stack {
      python_version = "3.11" # Adjust to match your Python version if necessary
    }
    cors {
      allowed_origins = ["*"] # Allows your frontend to hit the API
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    
    # Notice how we pull the connection string dynamically from the Cosmos block above!
    "CosmosDBConnectionString"       = azurerm_cosmosdb_account.db_account.primary_sql_connection_string
    
    # Link App Insights for logging
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.app_insights.instrumentation_key

    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"

  }
}

# =========================================================
# Azure Static Web Apps (Frontend Hosting)
# =========================================================
resource "azurerm_static_web_app" "swa" {
  name                = "swa-cloudresume-aidan1911"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "East Asia"
  sku_tier            = "Free"
  sku_size            = "Free"
}

# =========================================================
# Outputs
# =========================================================
output "swa_default_host_name" {
  value       = "https://${azurerm_static_web_app.swa.default_host_name}"
  description = "The URL of the new Azure Static Web App."
}

output "swa_deployment_token" {
  value       = azurerm_static_web_app.swa.api_key
  sensitive   = true
  description = "The deployment token required by GitHub Actions."
}

