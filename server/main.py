import os
import httpx
from fastapi import FastAPI, Request

app = FastAPI()

# DEV: Pull api key from local env
LINKUP_API_KEY = os.getenv("LINKUP_API_KEY")

@app.post("/mcp")
async def mcp_handler(request: Request):
    body = await request.json()
    method = body.get("method")
    request_id = body.get("id")
    
    # Initialize through handshake between Gemini and server
    if method == "tools/list":
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {"protocolVersion": "2024-11-05"}
        }

    # List tools: tell Gemini what tools are available
    if method == "tools/list":
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {"tools": [{
                "name": "search_linkedin",
                "description": "Search LinkedIn for profiles and professional news.",
                "inputSchema": {
                    "type": "object",
                    "properties":{"query": {"type": "string"}},
                    "required": ["query"]
                }
            }]}
        }

    # Call tool
    if method == "tools/call":
        query = body["params"]["arguments"]["query"]
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://api.linkup.so/v1/search",
                headers={"Authorization": f"Bearer {LINKUP_API_KEY}"},
                json={
                    "q": query,
                    "depth": "standard",
                    "includeDomains": ["linkedin.com"]
                }
            )
            data = response.json()
            # Return the answer field from Linkup to Gemini
            return {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {"content": [{"type": "text", "text": str(data.get("answer", "No results found."))}]}
            }
