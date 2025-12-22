import re

class IntentAnalyzer:
    def __init__(self):
        # 1. RETRIEVAL / QUESTIONS (Highest Priority)
        self.retrieval_patterns = [
            # --- START OF SENTENCE QUESTIONS ---
            r"^\s*when\b",           # "When is..."
            r"^\s*what\b",           # "What is..."
            r"^\s*where\b",          # "Where is..."
            
            # --- MID-SENTENCE / SPECIFIC QUESTIONS (The Fix!) ---
            r"\bwhat to do\b",       # Matches: "... what to do?"
            r"\bwhat should i\b",    # Matches: "... what should I do?"
            r"\bwhen is\b",          # Matches: "... when is it?"
            r"\bwhen was\b",         # Matches: "... when was that?"
            
            # --- SEARCH COMMANDS ---
            r"\bcheck\b",            # "Check if I have..."
            r"\bsearch\b",           # "Search for..."
            r"\bdo i have\b",        # "Do I have a meeting?"
            r"\bam i free\b",        # "Am I free?"
            r"\bfind\b",             # "Find the note..."
            r"\bshow me\b",
            r"\bhistory\b"
        ]

        # 2. HYPOTHETICAL MARKERS (Medium Priority)
        # We only check these if it wasn't a question.
        self.hypothetical_patterns = [
            r"\bsuppose\b", 
            r"\bimagine\b", 
            r"\bwhat if\b", 
            r"\blet's say\b", 
            r"\bassuming\b", 
            r"\bhypothetically\b"
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
            r"\bhave a\b"         
        ]

    def analyze(self, text: str):
        text_lower = text.lower().strip()
        
        # --- LAYER 1: IS IT A QUESTION? (Highest Priority) ---
        for pattern in self.retrieval_patterns:
            if re.search(pattern, text_lower):
                return {
                    "type": "retrieval", 
                    "confidence": "high", 
                    "action": "search_db",
                    "reason": f"Detected question/retrieval keyword: '{pattern}'"
                }

        # --- LAYER 2: IS IT HYPOTHETICAL? ---
        for pattern in self.hypothetical_patterns:
            if re.search(pattern, text_lower):
                return {
                    "type": "assumption", 
                    "confidence": "high", 
                    "action": "ignore", 
                    "reason": f"Detected hypothetical keyword: '{pattern}'"
                }

        # --- LAYER 3: IS IT A COMMAND? ---
        is_direct_command = any(re.search(p, text_lower) for p in self.action_patterns)
        
        if is_direct_command:
            return {
                "type": "command",
                "confidence": "high",
                "action": "execute",
                "reason": "Action verb detected."
            }

        # --- LAYER 4: JUST CONVERSATION ---
        return {
            "type": "conversation_or_noise",
            "confidence": "medium",
            "action": "log_only",
            "reason": "No specific command or question detected."
        }