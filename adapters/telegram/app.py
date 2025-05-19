from fastapi import FastAPI, Request, status

app = FastAPI(title="Telegram Adapter")


@app.post("/telegram/webhook", status_code=status.HTTP_200_OK)
async def telegram_webhook(req: Request) -> dict:
    await req.json()  # Parse request body
    # TODO: route message to IntentRouter
    return {"ok": True}
