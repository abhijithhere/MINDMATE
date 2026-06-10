# Chat Messages to chat_messages Table Fix - TODO Steps

## Approved Plan Breakdown:
1. **[x]** Update `backend/services/db_helper.py`: Replace model.encode with rag.embedder.generate_embedding in log_chat.
2. **[x]** Update `backend/app/nlp.py`: Import & use rag.embedder.generate_embedding.
3. **[x]** Update `backend/app/routers/chat.py`: 
   - Set SILENCE_THRESHOLD_SECONDS = 3
   - Add imports (log_chat, get_db)
   - Log AI reply with log_chat after every response
   - Add GET /history endpoint
   - Fix /send to accept JSON body (use Pydantic model)
4. **[x]** Restart backend & test endpoints (curl/postman)
5. **[x]** Verify DB inserts (SELECT * FROM chat_messages)
6. **[ ]** Test frontend chat_history_screen
7. **[X]** Complete task & attempt_completion

**Progress: Starting step 1**

