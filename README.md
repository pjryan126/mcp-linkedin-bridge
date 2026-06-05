# LinkedIn MCP Bridge

A serverless Model Context Protocol (MCP) server that connects developer AI clients (like Gemini CLI, Claude Desktop, or Cursor) to real-time LinkedIn professional data using the Linkup.so API and Google Cloud Run.

## Architecture Overview

* **Application Layer:** Python FastAPI server implementing the Model Context Protocol lifecycle (`initialize`, `tools/list`, `tools/call`).
* **Compute:** Google Cloud Run (Scales to zero, meaning idle costs are $0).
* **Data Provider:** Linkup.so API (Agentic web search engine configured to return synthesized `sourcedAnswer` formats).
* **Infrastructure as Code:** Terraform with remote state management in Google Cloud Storage (GCS).
* **CI/CD:** GitHub Actions with secure, keyless Workload Identity Federation (WIF).
* **Secret Management:** Google Cloud Secret Manager (API keys are never hardcoded).

---

## Prerequisites

Before deploying this stack, ensure you have the following installed and configured:

* Google Cloud CLI (`gcloud`)
* Terraform
* Docker
* Git & a GitHub account
* A Linkup.so API Key (The Free Tier offers ~1,000 requests/month)

---

## Deployment Guide

### 1. Google Cloud Environment Setup

Authenticate your local terminal and prepare your GCP project:

```bash
# Authenticate your CLI and set up Application Default Credentials (ADC) for Terraform
gcloud auth login
gcloud auth application-default login

# Set your active project
gcloud config set project YOUR_PROJECT_ID

# Enable required GCP APIs
gcloud services enable run.googleapis.com \
    secretmanager.googleapis.com \
    iam.googleapis.com \
    iamcredentials.googleapis.com \
    artifactregistry.googleapis.com

```

> **Troubleshooting ADC:** If Terraform later throws a "could not find default credentials" error, you may need to explicitly link your quota project by running: `gcloud auth application-default set-quota-project YOUR_PROJECT_ID`

### 2. Inject Secrets Securely

Do not put your Linkup.so API key in the codebase. Inject it directly into GCP Secret Manager to create "Version 1" of the payload:

```bash
echo -n "your_linkup_api_key_here" | gcloud secrets create linkup-api-key --data-file=-

```

### 3. Deploy the Infrastructure (Phase 1: State & Registry)

Before Terraform can deploy Cloud Run, it needs a place to store its state and a place for the Docker image to live.

```bash
# Create the remote state bucket
gcloud storage buckets create gs://YOUR_PROJECT_ID-terraform-state --location=us-central1

# Navigate to the terraform directory and initialize
cd terraform/
terraform init
terraform apply -target=google_artifact_registry_repository.mcp_linkedin_bridge_repo

```

*Note: You cannot deploy the full `terraform apply` yet. Cloud Run will crash if the Docker image does not exist in the Artifact Registry. We will let GitHub Actions handle the final deployment.*

### 4. CI/CD Pipeline (GitHub Actions & Workload Identity Federation)

This project uses keyless authentication. GitHub will securely authenticate to GCP, build/push the Docker container, and run the final `terraform apply`.

Run these commands locally, replacing `YOUR_PROJECT_ID`, `YOUR_PROJECT_NUMBER`, and `YOUR_GITHUB_USERNAME`:

```bash
# Create Service Account for GitHub Actions
gcloud iam service-accounts create github-actions-sa --display-name="GitHub Actions Deployer"

# Grant the pipeline permission to deploy infrastructure
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/owner"

# Create Identity Pool & OIDC Provider
gcloud iam workload-identity-pools create github-actions-pool --location="global"

gcloud iam workload-identity-pools providers create-oidc github-provider \
  --location="global" \
  --workload-identity-pool="github-actions-pool" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == 'YOUR_GITHUB_USERNAME'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Bind permissions strictly to your specific repository
gcloud iam service-accounts add-iam-policy-binding github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/YOUR_PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/YOUR_GITHUB_USERNAME/mcp-linkedin-bridge"

# Grant permission to mint OAuth tokens for Docker registry pushes
gcloud iam service-accounts add-iam-policy-binding github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.serviceAccountTokenCreator" \
  --member="principalSet://iam.googleapis.com/projects/YOUR_PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/YOUR_GITHUB_USERNAME/mcp-linkedin-bridge"

```

Once executed, push your code to the `main` branch. The `.github/workflows/deploy.yml` pipeline will automatically trigger, pushing your Docker container and deploying the latest Git hash to Cloud Run.

---

## Client Configuration

To connect this remote MCP server to your local Gemini CLI environment, add your live Cloud Run endpoint to your local settings.

**1. Open your configuration file:** `~/.gemini/settings.json`
**2. Append the server block:**

```json
{
  "mcpServers": {
    "linkedin-bridge": {
      "type": "http",
      "url": "https://mcp-linkedin-bridge-xxxxxxx-uc.a.run.app/mcp"
    }
  }
}

```

---

## Usage Example

Once the setup is complete, prompt Gemini naturally in your chat interface using explicit prompt engineering:

> *"Use the linkedin-bridge tool to search for current job postings on LinkedIn for roles equivalent to 'Vice President Data' or 'Head of Data' located in the New York City (NYC) metropolitan area. Extract a comprehensive, bulleted list detailing the Company Name, Job Title, and a one-sentence summary."*