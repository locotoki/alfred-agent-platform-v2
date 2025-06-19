FROM python:3.12-slim
WORKDIR /app
COPY . .
RUN pip install -r agents/$AGENT/requirements.txt || true
ENTRYPOINT ["python","-m","$AGENT.entrypoint"]
