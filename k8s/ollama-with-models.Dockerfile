FROM ollama/ollama:latest

# Set environment variables for optimal performance
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434
ENV OLLAMA_MODELS=/root/.ollama/models

# Create ollama directory and set permissions
RUN mkdir -p /root/.ollama/models && \
    chmod -R 755 /root/.ollama

# Download and embed the llama3.2 model during build
# This ensures the model is baked into the image
RUN nohup ollama serve > /tmp/ollama.log 2>&1 & \
    sleep 15 && \
    echo "Downloading llama3.2 model..." && \
    ollama pull llama3.2 && \
    echo "Model downloaded successfully!" && \
    ollama list && \
    echo "Stopping ollama server..." && \
    pkill -f ollama && \
    sleep 5 && \
    echo "Model embedding complete"

# Verify the model is properly stored
RUN ls -la /root/.ollama/models/ && \
    echo "Model files verified in image"

# Expose port
EXPOSE 11434

# Start ollama server (model is already embedded)
ENTRYPOINT ["/bin/ollama"]
CMD ["serve"] 