import asyncioLFimport jsonLFimport loggingLFimport osLFLFfrom aiokafka import AIOKafkaConsumer, AIOKafkaProducerLFLFlog = logging.getLogger("wa-bridge")LFKAFKA = os.getenv("KAFKA_BROKERS", "kafka:9092")
IN_T = os.getenv("WA_INBOUND_TOPIC", "wa.inbound")
OUT_T = os.getenv("WA_OUTBOUND_TOPIC", "wa.outbound")


async def _loop(core_send):
    """core_send(text:str, from_:str) -> str  # your existing handler"""
    prod = AIOKafkaProducer(bootstrap_servers=KAFKA)
    cons = AIOKafkaConsumer(
        IN_T,
        bootstrap_servers=KAFKA,
        auto_offset_reset="earliest",
        enable_auto_commit=True,
        group_id="agent-core-wa",
    )
    await prod.start()
    await cons.start()
    log.info("WA bridge up — listening for messages")
    try:
        async for msg in cons:
            try:
                body = json.loads(msg.value)
                m = body["messages"][0]  # minimal parse
                sender = m["from"]
                text = m["text"]["body"]
                reply = await core_send(text, sender)  # call into core
                payload = {"to": sender, "type": "text", "text": {"body": reply}}
                await prod.send_and_wait(OUT_T, json.dumps(payload).encode())
            except Exception as e:
                log.exception("bridge err: %s", e)
    finally:
        await prod.stop()
        await cons.stop()


# entrypoint helper -----------------------------------------------------------------
def start(core_send):
    asyncio.create_task(_loop(core_send))
