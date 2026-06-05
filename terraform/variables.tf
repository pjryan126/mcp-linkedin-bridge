variable "project_id" {
    description = "Google Cloud Project ID"
    type = string
}

variable "region" {
    description = "Google Cloud Region"
    type = string
    default = "us-central1"
}

variable "service_name" {
    description = "Name of the service"
    type = string
    default = "mcp-linkedin-bridge"
}

variable "image_tag" {
    description = "The Docker image tag to deploy (populated by CI/CD)"
    type = string
    default = "latest"
}

