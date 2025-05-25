// SPDX-License-Identifier: Apache-2.0
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
# ---- required by CI template ----
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD curl -f http://localhost:8081/healthz || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8081"]
