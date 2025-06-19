FROM python:3.12-slim
WORKDIR /app
COPY . .
RUN pip install PyGithub nats-py GitPython
ENTRYPOINT ["python","-m","auto_eng.worker"]