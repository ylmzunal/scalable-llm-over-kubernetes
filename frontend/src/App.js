import React, { useState, useEffect, useRef } from 'react';
import {
  Container,
  Paper,
  TextField,
  Button,
  Typography,
  Box,
  Avatar,
  Chip,
  CircularProgress,
  Alert,
  AppBar,
  Toolbar,
  IconButton,
  Divider,
  Card,
  CardContent
} from '@mui/material';
import {
  Send as SendIcon,
  Android as BotIcon,
  Person as PersonIcon,
  CloudQueue as CloudIcon,
  Speed as SpeedIcon,
  Computer as ComputerIcon
} from '@mui/icons-material';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { v4 as uuidv4 } from 'uuid';
import axios from 'axios';

// Create a modern theme
const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#f50057',
    },
    background: {
      default: '#f5f5f5',
      paper: '#ffffff',
    },
  },
  shape: {
    borderRadius: 12,
  },
});

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

function App() {
  const [messages, setMessages] = useState([]);
  const [inputMessage, setInputMessage] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [connectionStatus, setConnectionStatus] = useState('disconnected');
  const [conversationId] = useState(uuidv4());
  const [stats, setStats] = useState(null);
  const [error, setError] = useState(null);
  const messagesEndRef = useRef(null);
  const wsRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(scrollToBottom, [messages]);

  useEffect(() => {
    // Initialize WebSocket connection
    initializeWebSocket();
    
    // Fetch initial stats
    fetchStats();
    
    // Cleanup on unmount
    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, []);

  const initializeWebSocket = () => {
    try {
      const wsUrl = `ws://${window.location.hostname}:8000/ws/${conversationId}`;
      wsRef.current = new WebSocket(wsUrl);

      wsRef.current.onopen = () => {
        setConnectionStatus('connected');
        setError(null);
        console.log('WebSocket connected');
      };

      wsRef.current.onmessage = (event) => {
        const data = JSON.parse(event.data);
        
        if (data.type === 'system') {
          // Handle system messages
          console.log('System message:', data.message);
        } else if (data.response) {
          // Handle chat responses
          setMessages(prev => [...prev, {
            id: uuidv4(),
            text: data.response,
            sender: 'bot',
            timestamp: data.timestamp
          }]);
        }
        
        setIsLoading(false);
      };

      wsRef.current.onclose = () => {
        setConnectionStatus('disconnected');
        console.log('WebSocket disconnected');
        
        // Attempt to reconnect after 5 seconds
        setTimeout(() => {
          if (wsRef.current?.readyState === WebSocket.CLOSED) {
            initializeWebSocket();
          }
        }, 5000);
      };

      wsRef.current.onerror = (error) => {
        setConnectionStatus('error');
        setError('WebSocket connection failed. Falling back to HTTP API.');
        console.error('WebSocket error:', error);
      };

    } catch (error) {
      console.error('Failed to initialize WebSocket:', error);
      setError('Failed to establish real-time connection. Using HTTP API.');
    }
  };

  const fetchStats = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/stats`);
      setStats(response.data);
    } catch (error) {
      console.error('Failed to fetch stats:', error);
    }
  };

  const sendMessage = async () => {
    if (!inputMessage.trim()) return;

    const userMessage = {
      id: uuidv4(),
      text: inputMessage,
      sender: 'user',
      timestamp: new Date().toISOString()
    };

    setMessages(prev => [...prev, userMessage]);
    setIsLoading(true);
    setError(null);

    try {
      if (wsRef.current?.readyState === WebSocket.OPEN) {
        // Send via WebSocket
        wsRef.current.send(JSON.stringify({
          message: inputMessage,
          conversation_id: conversationId
        }));
      } else {
        // Fallback to HTTP API
        const response = await axios.post(`${API_BASE_URL}/chat`, {
          message: inputMessage,
          conversation_id: conversationId
        });

        setMessages(prev => [...prev, {
          id: uuidv4(),
          text: response.data.response,
          sender: 'bot',
          timestamp: response.data.timestamp
        }]);
        setIsLoading(false);
      }
    } catch (error) {
      setError('Failed to send message. Please try again.');
      setIsLoading(false);
      console.error('Error sending message:', error);
    }

    setInputMessage('');
  };

  const handleKeyPress = (event) => {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      sendMessage();
    }
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Box sx={{ flexGrow: 1, height: '100vh', display: 'flex', flexDirection: 'column' }}>
        <AppBar position="static" elevation={1}>
          <Toolbar>
            <BotIcon sx={{ mr: 2 }} />
            <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
              Scalable LLM Chatbot - Kubernetes Demo
            </Typography>
            <Box sx={{ display: 'flex', gap: 1 }}>
              <Chip
                icon={<CloudIcon />}
                label={connectionStatus === 'connected' ? 'Connected' : 'Disconnected'}
                color={connectionStatus === 'connected' ? 'success' : 'error'}
                size="small"
              />
              {stats && (
                <Chip
                  icon={<SpeedIcon />}
                  label={`${stats.llm_service?.messages_processed || 0} msgs`}
                  color="info"
                  size="small"
                />
              )}
            </Box>
          </Toolbar>
        </AppBar>

        <Container maxWidth="md" sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column', py: 2 }}>
          {error && (
            <Alert severity="warning" sx={{ mb: 2 }} onClose={() => setError(null)}>
              {error}
            </Alert>
          )}

          {stats && (
            <Card sx={{ mb: 2 }}>
              <CardContent sx={{ py: 1 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="body2" color="text.secondary">
                    Pod: {stats.system?.pod_name || 'local'} | 
                    Active Connections: {stats.connections?.active_websocket_connections || 0} |
                    Uptime: {Math.round(stats.llm_service?.uptime_seconds || 0)}s
                  </Typography>
                  <IconButton size="small" onClick={fetchStats}>
                    <ComputerIcon fontSize="small" />
                  </IconButton>
                </Box>
              </CardContent>
            </Card>
          )}

          <Paper 
            elevation={3} 
            sx={{ 
              flexGrow: 1, 
              display: 'flex', 
              flexDirection: 'column',
              overflow: 'hidden'
            }}
          >
            <Box sx={{ p: 2, bgcolor: 'primary.main', color: 'white' }}>
              <Typography variant="h6">
                Chat with AI Assistant
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.9 }}>
                This chatbot is running on Kubernetes with auto-scaling capabilities
              </Typography>
            </Box>

            <Box 
              sx={{ 
                flexGrow: 1, 
                overflow: 'auto', 
                p: 2,
                display: 'flex',
                flexDirection: 'column',
                gap: 2
              }}
            >
              {messages.length === 0 && (
                <Box sx={{ textAlign: 'center', py: 4, color: 'text.secondary' }}>
                  <BotIcon sx={{ fontSize: 48, mb: 2, opacity: 0.5 }} />
                  <Typography variant="h6">
                    Welcome to the Scalable LLM Chatbot
                  </Typography>
                  <Typography variant="body2">
                    Start a conversation to test the Kubernetes deployment
                  </Typography>
                </Box>
              )}

              {messages.map((message) => (
                <Box
                  key={message.id}
                  sx={{
                    display: 'flex',
                    justifyContent: message.sender === 'user' ? 'flex-end' : 'flex-start',
                    alignItems: 'flex-start',
                    gap: 1
                  }}
                >
                  {message.sender === 'bot' && (
                    <Avatar sx={{ bgcolor: 'primary.main', width: 32, height: 32 }}>
                      <BotIcon fontSize="small" />
                    </Avatar>
                  )}
                  
                  <Paper
                    sx={{
                      p: 2,
                      maxWidth: '70%',
                      bgcolor: message.sender === 'user' ? 'primary.main' : 'grey.100',
                      color: message.sender === 'user' ? 'white' : 'text.primary',
                    }}
                  >
                    <Typography variant="body1">
                      {message.text}
                    </Typography>
                    <Typography 
                      variant="caption" 
                      sx={{ 
                        opacity: 0.7,
                        display: 'block',
                        mt: 1
                      }}
                    >
                      {new Date(message.timestamp).toLocaleTimeString()}
                    </Typography>
                  </Paper>

                  {message.sender === 'user' && (
                    <Avatar sx={{ bgcolor: 'secondary.main', width: 32, height: 32 }}>
                      <PersonIcon fontSize="small" />
                    </Avatar>
                  )}
                </Box>
              ))}

              {isLoading && (
                <Box sx={{ display: 'flex', justifyContent: 'flex-start', alignItems: 'center', gap: 1 }}>
                  <Avatar sx={{ bgcolor: 'primary.main', width: 32, height: 32 }}>
                    <BotIcon fontSize="small" />
                  </Avatar>
                  <Paper sx={{ p: 2, bgcolor: 'grey.100' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <CircularProgress size={16} />
                      <Typography variant="body2" color="text.secondary">
                        AI is thinking...
                      </Typography>
                    </Box>
                  </Paper>
                </Box>
              )}

              <div ref={messagesEndRef} />
            </Box>

            <Divider />
            
            <Box sx={{ p: 2 }}>
              <Box sx={{ display: 'flex', gap: 1 }}>
                <TextField
                  fullWidth
                  multiline
                  maxRows={3}
                  value={inputMessage}
                  onChange={(e) => setInputMessage(e.target.value)}
                  onKeyPress={handleKeyPress}
                  placeholder="Type your message..."
                  variant="outlined"
                  size="small"
                  disabled={isLoading}
                />
                <Button
                  variant="contained"
                  onClick={sendMessage}
                  disabled={!inputMessage.trim() || isLoading}
                  sx={{ minWidth: 64 }}
                >
                  <SendIcon />
                </Button>
              </Box>
            </Box>
          </Paper>
        </Container>
      </Box>
    </ThemeProvider>
  );
}

export default App; 