import os

CHAT_MODEL = os.getenv("CHAT_MODEL", "gpt-5.4-mini")
EMBED_MODEL = os.getenv("EMBED_MODEL", "text-embedding-3-small")
EMBED_DIMENSIONS = 1536

DATABASE_URL = os.environ["DATABASE_URL"]
SMTP_HOST = os.getenv("SMTP_HOST", "localhost")
SUPPORT_FROM_ADDRESS = os.getenv("SUPPORT_FROM_ADDRESS", "support@helpdesk.example")

CARRIER_API_URL = os.getenv("CARRIER_API_URL", "https://api.carrier.example/v2")
CARRIER_API_KEY = os.environ["CARRIER_API_KEY"]

MAX_AGENT_STEPS = 8
MAX_CHUNK_DISTANCE = 0.55
