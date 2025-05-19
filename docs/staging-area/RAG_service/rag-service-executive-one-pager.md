# RAG Service – executive_one_pager

# RAG Platform — Executive One‑Pager

*Date: 2025-05-09*

**Problem**

Our agents struggle with siloed knowledge and hallucinations when answering queries.

**Solution**

Deploy a centrally‑hosted Retrieval‑Augmented Generation (RAG) Service that any agent can call to retrieve vetted context before the LLM produces an answer.

```
+-----------+          +-------------+
|  Agents   |====Req==>|  RAG Gateway|--+
+-----------+          +-------------+  |
                                         v
                                +-----------------+
                                |  Vector Store   |
                                |   (Qdrant)      |
                                +-----------------+
```

**Benefits**

* 30‑50 % reduction in LLM token spend (fewer retries)

* Enterprise‑grade audit trail and GDPR compliance

* Faster onboarding for new bots—one API, zero boiler‑plate

**Next Milestone (Week 3)**

Gateway MVP live with personal & business namespaces.
