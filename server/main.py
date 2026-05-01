import os
import httpx
from fastapi import FastAPI, Request

app = FastAPI()

# DEV: Pull api key from local env
LINKUP_API_KEY = os.getenv("LINKUP_API_KEY")


