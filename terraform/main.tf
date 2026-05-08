provider "google" {
    project = var.project_id
    region = var.region
}

# 1. Create a secret for the Linkup API key
resource "google_secret_manager_secret" "linkup_api_key" {
    secret_id = "linkup-api-key"
    
    replication {
        automatic = true
    }
}
