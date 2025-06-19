FROM python:3.12-slim
WORKDIR /app
COPY . .
RUN pip install openai psycopg2-binary nats-py
ENTRYPOINT ["python","-m","summariser.entrypoint"]