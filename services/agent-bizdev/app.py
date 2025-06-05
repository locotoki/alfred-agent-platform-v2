from fastapi import FastAPI
app = FastAPI()
@app.get("/health")
def health():
    return {"status": "ok"}
# TODO: implement /sync endpoint to push leads to CRM