import asyncio
import time
import logging
import os
from typing import Dict, Optional
from datetime import datetime
import httpx
import json

logger = logging.getLogger(__name__)

class LLMService:
    """
    LLM Service that handles AI model integration.
    Supports both local models and free API services.
    """
    
    def __init__(self):
        self.model_type = os.getenv("LLM_MODEL_TYPE", "ollama")  # ollama, openai, or mock
        self.model_name = os.getenv("LLM_MODEL_NAME", "llama2")
        self.api_key = os.getenv("OPENAI_API_KEY")
        self.base_url = os.getenv("LLM_BASE_URL", "http://localhost:11434")
        
        # Service metrics
        self.start_time = time.time()
        self.message_count = 0
        self.total_response_time = 0.0
        self.is_initialized = False
        self.conversations: Dict[str, list] = {}
        
        # Model status
        self.model_loaded = False
        self.last_health_check = None
        
    async def initialize(self):
        """Initialize the LLM service"""
        try:
            logger.info(f"Initializing LLM service with model type: {self.model_type}")
            
            if self.model_type == "ollama":
                await self._initialize_ollama()
            elif self.model_type == "openai":
                await self._initialize_openai()
            else:
                # Mock mode for testing
                await self._initialize_mock()
                
            self.is_initialized = True
            self.model_loaded = True
            logger.info("LLM service initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize LLM service: {e}")
            # Fallback to mock mode
            await self._initialize_mock()
            self.is_initialized = True
    
    async def _initialize_ollama(self):
        """Initialize Ollama local model"""
        try:
            async with httpx.AsyncClient() as client:
                # Check if Ollama is running
                response = await client.get(f"{self.base_url}/api/version", timeout=10.0)
                if response.status_code == 200:
                    logger.info("Ollama service is running")
                    
                    # Check if model is available
                    models_response = await client.get(f"{self.base_url}/api/tags")
                    if models_response.status_code == 200:
                        models = models_response.json()
                        available_models = [model['name'] for model in models.get('models', [])]
                        
                        if self.model_name in available_models:
                            logger.info(f"Model {self.model_name} is available")
                        else:
                            logger.warning(f"Model {self.model_name} not found. Pulling model...")
                            # Note: In production, models should be pre-pulled in Docker image
                            await self._pull_ollama_model()
                else:
                    raise Exception("Ollama service not accessible")
                    
        except Exception as e:
            logger.error(f"Ollama initialization failed: {e}")
            raise
    
    async def _pull_ollama_model(self):
        """Pull Ollama model if not available"""
        try:
            async with httpx.AsyncClient(timeout=300.0) as client:
                pull_data = {"name": self.model_name}
                response = await client.post(
                    f"{self.base_url}/api/pull",
                    json=pull_data
                )
                
                if response.status_code == 200:
                    logger.info(f"Successfully pulled model {self.model_name}")
                else:
                    raise Exception(f"Failed to pull model: {response.text}")
                    
        except Exception as e:
            logger.error(f"Model pull failed: {e}")
            raise
    
    async def _initialize_openai(self):
        """Initialize OpenAI API"""
        if not self.api_key:
            raise Exception("OpenAI API key not provided")
        
        # Test API connectivity
        try:
            async with httpx.AsyncClient() as client:
                headers = {"Authorization": f"Bearer {self.api_key}"}
                response = await client.get(
                    "https://api.openai.com/v1/models",
                    headers=headers,
                    timeout=10.0
                )
                
                if response.status_code == 200:
                    logger.info("OpenAI API connection successful")
                else:
                    raise Exception(f"OpenAI API error: {response.status_code}")
                    
        except Exception as e:
            logger.error(f"OpenAI initialization failed: {e}")
            raise
    
    async def _initialize_mock(self):
        """Initialize mock LLM for testing"""
        logger.info("Initializing mock LLM service for testing")
        await asyncio.sleep(1)  # Simulate initialization time
    
    async def process_message(self, message: str, conversation_id: str = None) -> str:
        """Process a chat message and return response"""
        start_time = time.time()
        
        try:
            # Get or create conversation history
            if conversation_id not in self.conversations:
                self.conversations[conversation_id] = []
            
            # Add user message to history
            self.conversations[conversation_id].append({
                "role": "user",
                "content": message,
                "timestamp": datetime.now().isoformat()
            })
            
            # Generate response based on model type
            if self.model_type == "ollama":
                response = await self._process_ollama_message(message, conversation_id)
            elif self.model_type == "openai":
                response = await self._process_openai_message(message, conversation_id)
            else:
                response = await self._process_mock_message(message, conversation_id)
            
            # Add assistant response to history
            self.conversations[conversation_id].append({
                "role": "assistant",
                "content": response,
                "timestamp": datetime.now().isoformat()
            })
            
            # Update metrics
            response_time = time.time() - start_time
            self.message_count += 1
            self.total_response_time += response_time
            
            logger.info(f"Processed message in {response_time:.2f}s")
            return response
            
        except Exception as e:
            logger.error(f"Error processing message: {e}")
            return f"I apologize, but I encountered an error processing your message: {str(e)}"
    
    async def _process_ollama_message(self, message: str, conversation_id: str) -> str:
        """Process message using Ollama"""
        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                # Get conversation context
                context = self._get_conversation_context(conversation_id)
                
                prompt_data = {
                    "model": self.model_name,
                    "prompt": f"Context: {context}\nUser: {message}\nAssistant:",
                    "stream": False
                }
                
                response = await client.post(
                    f"{self.base_url}/api/generate",
                    json=prompt_data
                )
                
                if response.status_code == 200:
                    result = response.json()
                    return result.get("response", "No response generated")
                else:
                    raise Exception(f"Ollama API error: {response.status_code}")
                    
        except Exception as e:
            logger.error(f"Ollama processing error: {e}")
            raise
    
    async def _process_openai_message(self, message: str, conversation_id: str) -> str:
        """Process message using OpenAI API"""
        try:
            async with httpx.AsyncClient() as client:
                # Build conversation history for OpenAI format
                messages = []
                messages.append({"role": "system", "content": "You are a helpful assistant."})
                
                # Add recent conversation history (last 10 messages)
                conversation_history = self.conversations.get(conversation_id, [])
                for msg in conversation_history[-10:]:
                    messages.append({
                        "role": msg["role"],
                        "content": msg["content"]
                    })
                
                headers = {"Authorization": f"Bearer {self.api_key}"}
                data = {
                    "model": "gpt-3.5-turbo",
                    "messages": messages,
                    "max_tokens": 500,
                    "temperature": 0.7
                }
                
                response = await client.post(
                    "https://api.openai.com/v1/chat/completions",
                    headers=headers,
                    json=data,
                    timeout=30.0
                )
                
                if response.status_code == 200:
                    result = response.json()
                    return result["choices"][0]["message"]["content"]
                else:
                    raise Exception(f"OpenAI API error: {response.status_code}")
                    
        except Exception as e:
            logger.error(f"OpenAI processing error: {e}")
            raise
    
    async def _process_mock_message(self, message: str, conversation_id: str) -> str:
        """Process message using mock responses for testing"""
        await asyncio.sleep(0.5)  # Simulate processing time
        
        mock_responses = [
            f"Thank you for your message: '{message}'. This is a mock response from the LLM service.",
            f"I understand you said: '{message}'. I'm a demo chatbot running on Kubernetes!",
            f"Hello! You mentioned: '{message}'. This response is generated by a scalable LLM service.",
            f"Interesting point about: '{message}'. I'm designed to scale automatically based on demand.",
            f"Thanks for sharing: '{message}'. This chatbot demonstrates Kubernetes deployment patterns."
        ]
        
        # Simple response selection based on message hash
        response_index = hash(message) % len(mock_responses)
        return mock_responses[response_index]
    
    def _get_conversation_context(self, conversation_id: str) -> str:
        """Get conversation context for Ollama prompts"""
        conversation = self.conversations.get(conversation_id, [])
        if not conversation:
            return "This is the start of a new conversation."
        
        # Format recent messages as context
        context_messages = []
        for msg in conversation[-5:]:  # Last 5 messages
            context_messages.append(f"{msg['role'].title()}: {msg['content']}")
        
        return "\n".join(context_messages)
    
    async def health_check(self) -> bool:
        """Check if the LLM service is healthy"""
        try:
            if self.model_type == "ollama":
                async with httpx.AsyncClient() as client:
                    response = await client.get(f"{self.base_url}/api/version", timeout=5.0)
                    healthy = response.status_code == 200
            elif self.model_type == "openai":
                async with httpx.AsyncClient() as client:
                    headers = {"Authorization": f"Bearer {self.api_key}"}
                    response = await client.get(
                        "https://api.openai.com/v1/models",
                        headers=headers,
                        timeout=5.0
                    )
                    healthy = response.status_code == 200
            else:
                healthy = True  # Mock is always healthy
            
            self.last_health_check = datetime.now()
            return healthy
            
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return False
    
    async def get_model_status(self) -> dict:
        """Get current model status"""
        return {
            "model_type": self.model_type,
            "model_name": self.model_name,
            "model_loaded": self.model_loaded,
            "is_initialized": self.is_initialized,
            "last_health_check": self.last_health_check.isoformat() if self.last_health_check else None
        }
    
    async def is_model_loaded(self) -> bool:
        """Check if model is loaded"""
        return self.model_loaded
    
    def get_message_count(self) -> int:
        """Get total message count"""
        return self.message_count
    
    def get_uptime(self) -> float:
        """Get service uptime in seconds"""
        return time.time() - self.start_time
    
    def get_average_response_time(self) -> float:
        """Get average response time"""
        if self.message_count == 0:
            return 0.0
        return self.total_response_time / self.message_count
    
    async def cleanup(self):
        """Cleanup resources"""
        logger.info("Cleaning up LLM service resources")
        self.conversations.clear()
        self.is_initialized = False 