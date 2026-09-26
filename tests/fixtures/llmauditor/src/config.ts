export const TRIAGE_MODEL = process.env.TRIAGE_MODEL ?? "claude-haiku-4-5-20251001";
export const MAX_TICKET_CHARS = 8000;
export const QUEUES = ["billing", "shipping", "returns", "technical"] as const;
export const PRIORITIES = ["low", "normal", "urgent"] as const;
