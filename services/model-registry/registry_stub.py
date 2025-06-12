from fastapi import FastAPILFLFapp = FastAPI()LF

@app.get("/health")
def health():
    return {"status": "ok"}
