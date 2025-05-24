FROM ollama/ollama:latest

# Set environment variables for optimal performance
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434
ENV OLLAMA_MODELS=/root/.ollama/models

# Create ollama directory and set permissions
RUN mkdir -p /root/.ollama/models && \
    chmod -R 755 /root/.ollama

# Download and embed TinyLlama model during build (very fast and lightweight)
# TinyLlama is only 1.1B parameters - perfect for demos
RUN nohup ollama serve > /tmp/ollama.log 2>&1 & \
    sleep 10 && \
    echo "Downloading TinyLlama model..." && \
    ollama pull tinyllama && \
    echo "Model downloaded successfully!" && \
    ollama list && \
    echo "Stopping ollama server..." && \
    pkill -f ollama && \
    sleep 3 && \
    echo "TinyLlama embedding complete"

# Verify the model is properly stored
RUN ls -la /root/.ollama/models/ && \
    echo "TinyLlama model files verified in image"

# Expose port
EXPOSE 11434

# Start ollama server (TinyLlama is already embedded)
ENTRYPOINT ["/bin/ollama"]
CMD ["serve"] 