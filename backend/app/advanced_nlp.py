import re

class IntentAnalyzer:
    def __init__(self):
        # 1. RETRIEVAL / QUESTIONS (Highest Priority)
        self.retrieval_patterns = [
            r"^\s*when\b",           # "When is..."
            r"^\s*what\b",           # "What is..."
            r"^\s*where\b",          # "Where is..."
            r"\bwhat to do\b",       # "... what to do?"
            r"\bwhat should i\b",    # "... what should I do?"
            r"\bwhen is\b",          # "... when is it?"
            r"\bcheck\b",            # "Check if I have..."
            r"\bsearch\b",           # "Search for..."
            r"\bfind\b",             # "Find the note..."
            r"\bshow me\b",
            r"\bhistory\b",
            r"\bread\b"              # "Read my emails"
        ]

        # 2. HYPOTHETICAL MARKERS (Medium Priority)
        self.hypothetical_patterns = [
            r"\bsuppose\b", 
            r"\bimagine\b", 
            r"\bwhat if\b", 
            r"\blet's say\b"
        ]

        # 3. ACTION / COMMAND MARKERS (Lower Priority)
        self.action_patterns = [
            r"\bschedule\b", 
            r"\bremind\b", 
            r"\bplan\b", 
            r"\bsave\b", 
            r"\bnote\b", 
            r"\bcreate\b", 
            r"\bcall\b", 
            r"\bbook\b",
            r"\bset a\b",
            # 👇 ADDED THESE NEW KEYWORDS 👇
            r"\bsend\b",             # "Send an email"
            r"\bwrite\b",            # "Write an email"
            r"\bemail\b",            # "Email bob"
            r"\bmail\b"              # "Mail bob"
        ]

    def analyze(self, text: str):
        text_lower = text.lower().strip()
        
        # --- LAYER 1: IS IT A QUESTION? ---
        for pattern in self.retrieval_patterns:
            if re.search(pattern, text_lower):
                return {
                    "type": "retrieval", 
                    "confidence": "high", 
                    "reason": f"Detected question keyword: '{pattern}'"
                }

        # --- LAYER 2: IS IT HYPOTHETICAL? ---
        for pattern in self.hypothetical_patterns:
            if re.search(pattern, text_lower):
                return {
                    "type": "assumption", 
                    "confidence": "high", 
                    "reason": f"Detected hypothetical keyword: '{pattern}'"
                }

        # --- LAYER 3: IS IT A COMMAND? ---
        # Now checks for "send", "email", etc.
        is_direct_command = any(re.search(p, text_lower) for p in self.action_patterns)
        
        if is_direct_command:
            return {
                "type": "command",
                "confidence": "high",
                "reason": "Action verb detected."
            }

        # --- LAYER 4: JUST CONVERSATION ---
        return {
            "type": "conversation_or_noise",
            "confidence": "medium",
            "reason": "No specific command or question detected."
        }