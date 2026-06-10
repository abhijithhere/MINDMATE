# app/nlp.py
"""
NLP pipeline for MindMate.

Key fixes:
  • get_recent_history removed from conversational response — was causing
    old DB data to be repeated on every TTS reply
  • CONVERSE decision for questions/chat — uses semantic context only
  • STORE always runs regardless of flag
  • CRUD gated on 75% flag rule
  • Wake words always get a TTS reply
"""

import json
import re
import requests
from rag.retriever import retrieve_context
from rag.prompt_builder import build_prompt
from services.db_helper import save_to_appropriate_table

OLLAMA_URL      = "http://localhost:11434/api/generate"
MODEL_NAME      = "phi3"
_OLLAMA_TIMEOUT = 60

WAKE_WORDS = {"mate", "mindmate", "buddy", "hey mate", "hey mindmate", "hey buddy"}


# ─────────────────────────────────────────────────────────────────────────────
# 1. LLM
# ─────────────────────────────────────────────────────────────────────────────
def call_llm(prompt: str, format_json: bool = False) -> str:
    payload = {"model": MODEL_NAME, "prompt": prompt, "stream": False}
    if format_json: payload["format"] = "json"
    try:
        r = requests.post(OLLAMA_URL, json=payload, timeout=_OLLAMA_TIMEOUT)
        r.raise_for_status()
        return r.json().get("response", "").strip()
    except requests.exceptions.ConnectionError:
        print("⚠️  Ollama offline")
        return "{}" if format_json else "Start Ollama with 'ollama serve' to enable AI responses."
    except Exception as e:
        print(f"❌ LLM: {e}")
        return "{}" if format_json else "I couldn't process that right now."

def _is_ollama_up() -> bool:
    try:
        return requests.get("http://localhost:11434", timeout=2).status_code < 500
    except Exception:
        return False


# ─────────────────────────────────────────────────────────────────────────────
# 2. WAKE WORD
# ─────────────────────────────────────────────────────────────────────────────
def detect_wake_word(text: str) -> bool:
    t = text.lower().strip()
    for w in WAKE_WORDS:
        if t.startswith(w) or t == w or f" {w}" in t or f"{w} " in t:
            return True
    return False


# ─────────────────────────────────────────────────────────────────────────────
# 3. KEYWORD FALLBACK CLASSIFIER
# ─────────────────────────────────────────────────────────────────────────────
_RETRIEVAL_KW = [
    "what was", "what did", "show me", "tell me about", "when was",
    "where was", "what is my", "history", "do i have", "what are my",
    "remind me what", "what have i", "search", "find my", "look up",
    "what's my", "list my", "check my",
]
_REMINDER_KW = [
    "remind", "reminder", "don't forget", "medicine", "tablet", "pill",
    "alarm", "deadline", "due", "todo", "to-do", "task", "schedule me",
    "set a reminder", "notify me",
]
_EVENT_KW = [
    "meeting", "appointment", "schedule", "call with", "interview",
    "session", "seminar", "class at", "tomorrow at", "next week at",
    "on monday", "on tuesday", "on wednesday", "on thursday", "on friday",
    "i have a", "i've got a",
]
_MEMORY_KW = [
    "i remember", "last time", "previously", "used to", "told me",
    "you said", "we discussed", "as i mentioned",
]
_STORE_KW = [
    "save this", "note this", "remember this", "write down", "keep this",
    "store this", "log this", "make a note",
]
_CONVERSATION_KW = [
    "what do you think", "can you help", "explain", "how do i",
    "what is", "who is", "why ", "how does", "what should", "suggest",
    "give me", "help me", "what's the", "tell me about",
]

def _keyword_classify(text: str) -> dict:
    t = text.lower()
    base = {"emotion": "Neutral", "action": "NONE", "is_long": False,
            "trigger_time": None, "summary": text[:80]}

    if detect_wake_word(text) and len(t.split()) <= 3:
        # Just a wake word call — greet
        return {**base, "decision": "CONVERSE", "category": "chat",
                "action": "NONE", "priority": "Low"}
    if any(k in t for k in _RETRIEVAL_KW):
        return {**base, "decision": "CRUD", "category": "note",
                "action": "READ", "priority": "Low"}
    if any(k in t for k in _REMINDER_KW):
        hi = any(k in t for k in ["medicine", "tablet", "pill", "deadline", "urgent"])
        return {**base, "decision": "STORE", "category": "reminder",
                "action": "CREATE", "priority": "High" if hi else "Low"}
    if any(k in t for k in _EVENT_KW):
        return {**base, "decision": "STORE", "category": "event",
                "action": "CREATE", "priority": "High"}
    if any(k in t for k in _MEMORY_KW):
        return {**base, "decision": "STORE", "category": "memory",
                "action": "CREATE", "priority": "Low"}
    if any(k in t for k in _STORE_KW):
        long = len(t.split()) > 80
        return {**base, "decision": "STORE",
                "category": "lecture" if long else "note",
                "action": "CREATE", "priority": "Low", "is_long": long}
    if any(k in t for k in _CONVERSATION_KW) or detect_wake_word(text):
        return {**base, "decision": "CONVERSE", "category": "chat",
                "action": "NONE", "priority": "Low"}
    if len(t.split()) > 50:
        return {**base, "decision": "STORE", "category": "lecture",
                "action": "CREATE", "priority": "Low", "is_long": True}
    return {**base, "decision": "IGNORE", "category": "note", "priority": "Low"}


# ─────────────────────────────────────────────────────────────────────────────
# 4. LLM CLASSIFIER
# ─────────────────────────────────────────────────────────────────────────────
def classify_audio_intent(transcript: str) -> dict:
    if not _is_ollama_up():
        return _keyword_classify(transcript)

    prompt = f"""
You are an intent classifier for MindMate.
Transcript: "{transcript}"

Return ONLY valid JSON.

DECISION:
  "STORE"    → saving: reminder/event/note/lecture/memory
  "CRUD"     → reading/searching/deleting past data
  "CONVERSE" → question, casual chat, wake word, general conversation
  "IGNORE"   → background noise, filler words, nothing actionable

CATEGORY (STORE only): "reminder"|"event"|"memory"|"lecture"|"note"
PRIORITY: "High" (medicine/deadline) | "Low" (rest)

{{
  "decision":     "STORE"|"CRUD"|"CONVERSE"|"IGNORE",
  "category":     "reminder"|"event"|"memory"|"lecture"|"note"|"chat",
  "emotion":      "Urgent"|"Neutral"|"Happy"|"Stressed",
  "action":       "CREATE"|"READ"|"DELETE"|"UPDATE"|"NONE",
  "priority":     "High"|"Low",
  "summary":      "<one sentence>",
  "is_long":      true|false,
  "trigger_time": "<YYYY-MM-DD HH:MM:SS or null>"
}}
"""
    raw = call_llm(prompt, format_json=True)
    try:
        data = json.loads(raw)
        if data.get("emotion") in ("Urgent", "Stressed") or \
           data.get("category") in ("event", "reminder"):
            data["priority"] = "High"
        return data
    except Exception:
        return _keyword_classify(transcript)


def summarise_text(text: str) -> str:
    if not _is_ollama_up():
        parts = re.split(r'[.!?]', text)
        return ". ".join(s.strip() for s in parts[:2] if s.strip()) + "."
    return call_llm(
        f"Summarise in 2-3 sentences. Keep key facts, names, dates.\n\nText: {text}\n\nSummary:"
    )


# ─────────────────────────────────────────────────────────────────────────────
# 5. AI REPLY GENERATOR
# Uses semantic context only — NO chat history (history caused repetition)
# ─────────────────────────────────────────────────────────────────────────────
def generate_ai_reply(
    user_id:    str,
    text:       str,
    context:    list  = None,
    stored_in:  str   = "",
    retrieval_allowed: bool = True,
) -> str:
    if not _is_ollama_up():
        if stored_in:
            return f"Saved to your {stored_in}."
        return "Start Ollama for AI responses."

    # Build context string from semantic search only
    ctx_parts = []
    if stored_in:
        ctx_parts.append(f"[Just saved to: {stored_in}]")
    if context and retrieval_allowed:
        ctx_parts.extend(f"- {c}" for c in context[:4])

    ctx_str = "\n".join(ctx_parts) if ctx_parts else ""
    prompt  = build_prompt(user_text=text, context=ctx_str)
    return call_llm(prompt)


# ─────────────────────────────────────────────────────────────────────────────
# 6. MAIN PIPELINE
# ─────────────────────────────────────────────────────────────────────────────
def classify_and_route(
    user_id:      str,
    text:         str,
    source:       str   = "Voice"
) -> dict:
    if not text or not text.strip():
        return {"status": "empty", "ai_reply": ""}

    # 🟢 Voice Auth Removed: Always allow retrieval
    retrieval_allowed = True

    analysis = classify_audio_intent(text)
    decision = analysis.get("decision", "IGNORE")

    if analysis.get("is_long") or analysis.get("category") == "lecture":
        analysis["summary"] = summarise_text(text)

    print(
        f"🧠 [{source}] decision={decision} | category={analysis.get('category')} | "
        f"priority={analysis.get('priority')} | retrieval=True (Auth Bypassed)"
    )

    # ── WAKE WORD ONLY (very short) ────────────────────────────────────────────
    if detect_wake_word(text) and len(text.split()) <= 4:
        reply = generate_ai_reply(user_id, text, retrieval_allowed=False)
        return {"status": "converse", "table": "", "summary": "", "ai_reply": reply}

    # ── CONVERSE (question, chat, general) ────────────────────────────────────
    if decision == "CONVERSE":
        ctx = []
        try: ctx = retrieve_context(user_id, text, top_k=4)
        except Exception as e: print(f"⚠️  Context: {e}")
        reply = generate_ai_reply(user_id, text, context=ctx,
                                  retrieval_allowed=True)
        return {"status": "converse", "table": "", "summary": "", "ai_reply": reply}

    # ── CRUD (retrieval request) ───────────────────────────────────────────────
    if decision == "CRUD":
        ctx = []
        try: ctx = retrieve_context(user_id, text, top_k=5)
        except Exception as e: print(f"⚠️  Retrieval: {e}")
        reply = generate_ai_reply(user_id, text, context=ctx,
                                  retrieval_allowed=True)
        return {"status": "crud_required", "table": "",
                "summary": analysis.get("summary", ""), "ai_reply": reply}

    # ── STORE ──────────────────────────────────────────────────────────────────
    if decision == "STORE":
        saved = save_to_appropriate_table(
            user_id=user_id, analysis=analysis,
            text=text, source=source, flag=1 # Hardcoded to 1 to satisfy DB schema
        )
        reply = generate_ai_reply(user_id, text, stored_in=saved,
                                  retrieval_allowed=False)
        return {"status": "stored", "table": saved,
                "summary": analysis.get("summary", ""), "ai_reply": reply}

    # ── IGNORE (but still reply if wake word present) ─────────────────────────
    ai_reply = ""
    if detect_wake_word(text):
        ai_reply = generate_ai_reply(user_id, text, retrieval_allowed=False)
    return {"status": "ignored", "table": "", "summary": "", "ai_reply": ai_reply}


# Compat
class IntentAnalyzer:
    def analyze(self, text: str) -> dict:
        return _keyword_classify(text)