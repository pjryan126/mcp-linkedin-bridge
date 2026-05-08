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


