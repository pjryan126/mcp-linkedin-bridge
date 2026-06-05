terraform {
    backend "gcs" {
        bucket = "mcp-linkedin-bridge-tf-state"
        prefix = "terraform/state"
    }
}

provider "google" {
    project = var.project_id
    region = var.region
}

# 1. Create a secret for the Linkup API key
resource "google_secret_manager_secret" "linkup_api_key" {
    secret_id = "linkup-api-key"
    
    replication {
        auto {}
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
    name = "mcp-linkedin-bridge"
    location = var.region
    
    template {
        spec {
            service_account_name = google_service_account.mcp_runner.email
            containers {
                # This URL follows: {REGION}-docker.pkg.dev/{PROJECT}/{REPO}/{IMAGE}:{TAG}
                image = "us-central1-docker.pkg.dev/${var.project_id}/mcp-linkedin-bridge-repo/mcp-linkedin-bridge:${var.image_tag}"
                
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
    }

    traffic {
        percent = 100
        latest_revision = true
    }
}

# 4. Allow public access to the Cloud Run service
resource "google_cloud_run_service_iam_member" "public" {
    location = google_cloud_run_service.mcp_bridge.location
    service = google_cloud_run_service.mcp_bridge.name
    role = "roles/run.invoker"
    member = "allUsers"
}

# 5. Create a dedicated single-purpose identity for MCP bridge
resource "google_service_account" "mcp_runner" {
    account_id = "mcp-linkedin-bridge-runner"
    display_name = "MCP LinkedIn Bridge Execution SA"
}

# 6. Grant ONLY this new identify permission to read the LinkUp secret
resource "google_secret_manager_secret_iam_member" "cloud_run_secret_access" {
    secret_id   = google_secret_manager_secret.linkup_api_key.id
    role        = "roles/secretmanager.secretAccessor"
    member      = "serviceAccount:${google_service_account.mcp_runner.email}"
}

