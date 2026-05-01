# MCP - LinkedIn Bridge
A MCP server deployed on Google Cloud Run to access LinkedIn data in Google Gemini using the Linkup.so API

## Architecture
- **Transport**: HTTP (FastAPI)
- **Deployment**: Google Cloud Run
- **Data Engine**: Linkup.so
- **Infrastructure**: Terraform

## Local Development
1. `pip install -r server/requirements.txt`
2. `uvicorn server.main:app --reload`