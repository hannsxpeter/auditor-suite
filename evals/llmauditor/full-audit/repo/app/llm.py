from openai import OpenAI
from tenacity import retry, retry_if_exception_type, stop_after_attempt, wait_random_exponential

from app import config

client = OpenAI(timeout=30.0, max_retries=0)


@retry(
    retry=retry_if_exception_type(ConnectionError),
    stop=stop_after_attempt(4),
    wait=wait_random_exponential(multiplier=1, max=20),
    reraise=True,
)
def chat(messages, **kwargs):
    return client.chat.completions.create(model=config.CHAT_MODEL, messages=messages, **kwargs)
