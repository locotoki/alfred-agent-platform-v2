FROM python:3.12-slim
WORKDIR /app
COPY . .
RUN pip install -r agents/reviewer/requirements.txt
ENTRYPOINT ["python","-m","reviewer.entrypoint"]
