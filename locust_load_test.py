from locust import HttpUser, task, between
import random
import json

class LLMChatbotUser(HttpUser):
    wait_time = between(1, 3)  # Wait 1-3 seconds between requests
    
    def on_start(self):
        """Called when a user starts"""
        self.user_id = random.randint(1000, 9999)
        
    @task(3)
    def health_check(self):
        """Health check endpoint - lighter load"""
        with self.client.get("/health", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Health check failed with status {response.status_code}")
    
    @task(2)
    def chat_request(self):
        """Chat request - heavier load"""
        messages = [
            "What is Kubernetes?",
            "Explain auto-scaling in cloud computing",
            "How does load balancing work?",
            "What are the benefits of containerization?",
            "Tell me about microservices architecture",
            "How do you scale applications horizontally?",
            "What is the difference between CPU and memory scaling?",
            "Explain high availability in distributed systems"
        ]
        
        payload = {
            "message": random.choice(messages),
            "conversation_id": f"load-test-{self.user_id}-{random.randint(1, 100)}"
        }
        
        with self.client.post("/chat", 
                             json=payload,
                             headers={"Content-Type": "application/json"},
                             catch_response=True) as response:
            if response.status_code == 200:
                try:
                    response_data = response.json()
                    if "response" in response_data:
                        response.success()
                    else:
                        response.failure("No response field in JSON")
                except json.JSONDecodeError:
                    response.failure("Invalid JSON response")
            else:
                response.failure(f"Chat request failed with status {response.status_code}")
    
    @task(1)
    def stress_request(self):
        """Stress request - very heavy load to trigger scaling"""
        payload = {
            "message": "Generate a comprehensive explanation of distributed systems, microservices, containerization, orchestration, auto-scaling, load balancing, high availability, fault tolerance, and performance optimization in cloud-native applications.",
            "conversation_id": f"stress-test-{self.user_id}-{random.randint(1, 50)}"
        }
        
        with self.client.post("/chat",
                             json=payload,
                             headers={"Content-Type": "application/json"},
                             catch_response=True,
                             timeout=30) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Stress request failed with status {response.status_code}") 