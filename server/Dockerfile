# 1. Add Python slim
FROM python:3.13-slim

# 2. Set working directory
WORKDIR /app

# 3. Copy requirements
COPY requirements.txt .

# 4. Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy application code
COPY main.py .

# 6. Expose port
EXPOSE 8080

# 7. Run application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
