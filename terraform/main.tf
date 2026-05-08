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

# 2. Artifact Registry to host Docker images
resource "google_artifact_registry_repository" "mcp_linkedin_bridge_repo" {
    location = var.region
    repository_id = "mcp-linkedin-bridge-repo"
    format = "DOCKER"
    description = "Docker images for the LinkedIn Bridge MCP server"
}

# 3. Cloud Run Service (The Serverless Compute)
resource "google_cloud_run_service" "mcp_bridge" {
    name = var.service_name
    location = var.region
    description = "LinkedIn Bridge MCP Server"
    
    template {
        containers {
            # This URL follows: {REGION}-docker.pkg.dev/{PROJECT}/{REPO}/{IMAGE}:{TAG}
            image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.mcp_linkedin_bridge_repo.repository_id}/mcp-linkedin-bridge:latest"
            
            env {
                name = "LINKUP_API_KEY"
                value_from {
                    secret_key_ref {
                        name = google_secret_manager_secret.linkup_api_key.secret_id
                        key = "latest"
                    }
                }
            }
            
        }
    }

    traffic {
        percent = 100
        latest_revision = true
    }
}

# 4. Allow public access to the Cloud Run service
resource "google_cloud_run_iam_member" "public_access" {
    location = google_cloud_run_service.mcp_bridge.location
    service = google_cloud_run_service.mcp_bridge.name
    role = "roles/run.invoker"
    member = "allUsers"
}
