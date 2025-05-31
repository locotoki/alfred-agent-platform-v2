from fastapi import FastAPI
app = FastAPI()
@app.get("/health")
def health():
    return {"status": "ok"}
@app.get("/v1/models")
def models():
    return {"models": []}