from locust import HttpUser, task, between

class RAGUser(HttpUser):
    wait_time = between(0.1, 0.1)
    host = "http://localhost:8080"  # updated port

    @task
    def query_rag(self):
        res = self.client.post("/v1/query", json={"query": "When is GA?"})
        if res.status_code != 200:
            res.failure("Non-200 response")
        else:
            try:
                j = res.json()
                assert isinstance(j["citations"], list)
            except Exception as e:
                res.failure(f"Bad JSON: {e}")
