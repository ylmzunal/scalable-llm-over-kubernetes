#!/usr/bin/env python3
"""
Test script to verify local Ollama model deployment
This script tests that the application works with local models instead of OpenAI
"""

import os
import sys
import asyncio
import httpx
import json
from typing import Dict, Any

# Test configuration
TEST_BASE_URL = "http://localhost:8000"
OLLAMA_BASE_URL = "http://localhost:11434"

async def test_ollama_connectivity():
    """Test if Ollama is running and accessible"""
    print("🔍 Testing Ollama connectivity...")
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{OLLAMA_BASE_URL}/api/version", timeout=5.0)
            if response.status_code == 200:
                version_info = response.json()
                print(f"✅ Ollama is running - Version: {version_info.get('version', 'Unknown')}")
                return True
            else:
                print(f"❌ Ollama responded with status {response.status_code}")
                return False
    except Exception as e:
        print(f"❌ Failed to connect to Ollama: {e}")
        print("💡 Make sure Ollama is running: ollama serve")
        return False

async def test_ollama_models():
    """Test what models are available in Ollama"""
    print("\n🤖 Checking available Ollama models...")
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=10.0)
            if response.status_code == 200:
                models_data = response.json()
                models = models_data.get('models', [])
                if models:
                    print("✅ Available models:")
                    for model in models:
                        name = model.get('name', 'Unknown')
                        size = model.get('size', 0)
                        size_gb = size / (1024**3) if size > 0 else 0
                        print(f"   • {name} ({size_gb:.1f} GB)")
                    return True
                else:
                    print("⚠️  No models found in Ollama")
                    print("💡 Download models with: ollama pull phi")
                    return False
            else:
                print(f"❌ Failed to get models list: {response.status_code}")
                return False
    except Exception as e:
        print(f"❌ Error checking models: {e}")
        return False

async def test_app_health():
    """Test if the FastAPI application is healthy"""
    print("\n🏥 Testing application health...")
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{TEST_BASE_URL}/health", timeout=10.0)
            if response.status_code == 200:
                health_data = response.json()
                print("✅ Application is healthy")
                print(f"   Status: {health_data.get('status', 'Unknown')}")
                print(f"   Model Provider: {health_data.get('model_provider', 'Unknown')}")
                print(f"   Model Name: {health_data.get('model_name', 'Unknown')}")
                return True
            else:
                print(f"❌ Health check failed: {response.status_code}")
                return False
    except Exception as e:
        print(f"❌ Failed to connect to application: {e}")
        print("💡 Make sure the application is running on port 8000")
        return False

async def test_model_switch():
    """Test switching between models"""
    print("\n🔄 Testing model switching...")
    try:
        async with httpx.AsyncClient() as client:
            # Get available models
            response = await client.get(f"{TEST_BASE_URL}/models", timeout=10.0)
            if response.status_code == 200:
                models_data = response.json()
                available_models = models_data.get('available_models', {})
                ollama_models = available_models.get('ollama', [])
                
                if ollama_models:
                    # Try to switch to first available model
                    test_model = ollama_models[0]['name']
                    switch_data = {
                        "provider": "ollama",
                        "model_name": test_model
                    }
                    
                    response = await client.post(
                        f"{TEST_BASE_URL}/models/switch",
                        json=switch_data,
                        timeout=30.0
                    )
                    
                    if response.status_code == 200:
                        result = response.json()
                        if result.get('success'):
                            print(f"✅ Successfully switched to model: {test_model}")
                            return True
                        else:
                            print(f"❌ Model switch failed: {result.get('message', 'Unknown error')}")
                            return False
                    else:
                        print(f"❌ Model switch request failed: {response.status_code}")
                        return False
                else:
                    print("⚠️  No Ollama models available for switching")
                    return False
            else:
                print(f"❌ Failed to get available models: {response.status_code}")
                return False
    except Exception as e:
        print(f"❌ Error testing model switch: {e}")
        return False

async def test_chat_functionality():
    """Test basic chat functionality"""
    print("\n💬 Testing chat functionality...")
    try:
        async with httpx.AsyncClient() as client:
            chat_data = {
                "message": "Hello! Can you tell me what model you are?",
                "conversation_id": "test-conversation"
            }
            
            response = await client.post(
                f"{TEST_BASE_URL}/chat",
                json=chat_data,
                timeout=60.0  # Longer timeout for model inference
            )
            
            if response.status_code == 200:
                result = response.json()
                response_text = result.get('response', '')
                model_info = result.get('model_info', {})
                
                print("✅ Chat functionality working")
                print(f"   Model: {model_info.get('display_name', 'Unknown')}")
                print(f"   Response: {response_text[:100]}...")
                return True
            else:
                print(f"❌ Chat request failed: {response.status_code}")
                try:
                    error_detail = response.json()
                    print(f"   Error: {error_detail}")
                except:
                    print(f"   Raw response: {response.text}")
                return False
    except Exception as e:
        print(f"❌ Error testing chat: {e}")
        return False

async def verify_no_openai_usage():
    """Verify that OpenAI is not being used"""
    print("\n🔍 Verifying no OpenAI usage...")
    
    # Check if OpenAI API key is set (should not be needed)
    openai_key = os.getenv('OPENAI_API_KEY')
    if openai_key:
        print("⚠️  OPENAI_API_KEY is set but should not be needed")
    else:
        print("✅ No OPENAI_API_KEY detected (good!)")
    
    # Check application configuration
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{TEST_BASE_URL}/models/current", timeout=10.0)
            if response.status_code == 200:
                current_model = response.json()
                provider = current_model.get('provider', 'unknown')
                
                if provider == 'ollama':
                    print("✅ Application is using Ollama (local models)")
                    return True
                elif provider == 'openai':
                    print("❌ Application is still using OpenAI")
                    return False
                else:
                    print(f"ℹ️  Application is using provider: {provider}")
                    return True
            else:
                print("⚠️  Could not determine current model provider")
                return False
    except Exception as e:
        print(f"⚠️  Error checking model provider: {e}")
        return False

async def main():
    """Run all tests"""
    print("🚀 Testing Local LLM Deployment (No OpenAI)")
    print("=" * 50)
    
    tests = [
        ("Ollama Connectivity", test_ollama_connectivity),
        ("Ollama Models", test_ollama_models),
        ("Application Health", test_app_health),
        ("No OpenAI Usage", verify_no_openai_usage),
        ("Model Switching", test_model_switch),
        ("Chat Functionality", test_chat_functionality),
    ]
    
    results = {}
    
    for test_name, test_func in tests:
        try:
            results[test_name] = await test_func()
        except Exception as e:
            print(f"❌ {test_name} failed with exception: {e}")
            results[test_name] = False
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Results Summary")
    print("=" * 50)
    
    passed = 0
    total = len(tests)
    
    for test_name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} {test_name}")
        if result:
            passed += 1
    
    print(f"\nOverall: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed! Your local LLM deployment is working correctly.")
        print("✅ No OpenAI dependency")
        print("✅ Local models are running")
        print("✅ Application is functional")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed. Check the output above for details.")
        
        if not results.get("Ollama Connectivity", False):
            print("\n💡 Quick fix: Start Ollama with 'ollama serve'")
        
        if not results.get("Ollama Models", False):
            print("\n💡 Quick fix: Download models with 'ollama pull phi'")
    
    return passed == total

if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1) 