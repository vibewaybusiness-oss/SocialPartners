"use client";

import { useEffect, useRef, useCallback } from "react";

interface StreamingMessage {
  task_id: string;
  chat_id?: string;
  status: string;
  event_type?: string;
  token?: string;
  timestamp?: string;
  type?: string;
}

interface UseTaskStreamingOptions {
  chat_id?: string;
  task_id?: string;
  onToken?: (task_id: string, token: string) => void;
  onGenerationStarted?: (task_id: string) => void;
  onGenerationCompleted?: (task_id: string, full_text?: string) => void;
  onGenerationFailed?: (task_id: string, error: string) => void;
  onStatusUpdate?: (task_id: string, status: string, data?: any) => void;
  enabled?: boolean;
}

export function useTaskStreaming({
  chat_id,
  task_id,
  onToken,
  onGenerationStarted,
  onGenerationCompleted,
  onGenerationFailed,
  onStatusUpdate,
  enabled = true
}: UseTaskStreamingOptions) {
  const wsRef = useRef<WebSocket | null>(null);
  const reconnectTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const reconnectAttempts = useRef(0);
  const isConnectingRef = useRef(false);
  const shouldReconnectRef = useRef(true);
  const maxReconnectAttempts = 5;
  const reconnectDelay = 1000;

  const callbacksRef = useRef({
    onToken,
    onGenerationStarted,
    onGenerationCompleted,
    onGenerationFailed,
    onStatusUpdate
  });

  useEffect(() => {
    callbacksRef.current = {
      onToken,
      onGenerationStarted,
      onGenerationCompleted,
      onGenerationFailed,
      onStatusUpdate
    };
  }, [onToken, onGenerationStarted, onGenerationCompleted, onGenerationFailed, onStatusUpdate]);

  const connect = useCallback(() => {
    if (!enabled || !shouldReconnectRef.current) return;
    
    const currentState = wsRef.current?.readyState;
    if (currentState === WebSocket.OPEN || currentState === WebSocket.CONNECTING) {
      return;
    }

    if (isConnectingRef.current) {
      return;
    }

    try {
      isConnectingRef.current = true;
      const baseUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
      const params = new URLSearchParams();
      if (task_id) params.append('task_id', task_id);
      if (chat_id) params.append('chat_id', chat_id);
      
      const wsUrl = `${baseUrl.replace('http', 'ws')}/api/tasks/ws?${params.toString()}`;
      
      const ws = new WebSocket(wsUrl);
      
      ws.onopen = () => {
        console.log('[TaskStreaming] WebSocket connected', { task_id, chat_id });
        isConnectingRef.current = false;
        reconnectAttempts.current = 0;
        
        ws.send(JSON.stringify({
          type: 'subscribe',
          task_id,
          chat_id
        }));
      };

      ws.onmessage = (event) => {
        try {
          const data: StreamingMessage = JSON.parse(event.data);
          
          if (data.type === 'connected' || data.type === 'subscribed') {
            console.log('[TaskStreaming] Subscription confirmed', data);
            return;
          }

          const currentTaskId = data.task_id;
          const eventType = data.event_type || data.status;

          if (eventType === 'generation_started' || (eventType === 'generating' && data.event_type === 'generation_started')) {
            callbacksRef.current.onGenerationStarted?.(currentTaskId);
          } else if (eventType === 'token' && data.token) {
            callbacksRef.current.onToken?.(currentTaskId, data.token);
          } else if (eventType === 'generation_completed' || data.status === 'completed') {
            const fullText = (data as any).response_text || (data as any).full_text || '';
            callbacksRef.current.onGenerationCompleted?.(currentTaskId, fullText);
          } else if (eventType === 'generation_failed' || data.status === 'failed') {
            const error = (data as any).error || 'Generation failed';
            callbacksRef.current.onGenerationFailed?.(currentTaskId, error);
          } else if (data.status) {
            callbacksRef.current.onStatusUpdate?.(currentTaskId, data.status, data);
          }
        } catch (error) {
          console.error('[TaskStreaming] Error parsing message:', error);
        }
      };

      ws.onerror = (error) => {
        console.error('[TaskStreaming] WebSocket error:', error);
        isConnectingRef.current = false;
      };

      ws.onclose = (event) => {
        console.log('[TaskStreaming] WebSocket closed', { code: event.code, reason: event.reason });
        isConnectingRef.current = false;
        
        if (wsRef.current === ws) {
          wsRef.current = null;
        }

        if (shouldReconnectRef.current && enabled && reconnectAttempts.current < maxReconnectAttempts) {
          reconnectAttempts.current += 1;
          const delay = reconnectDelay * Math.pow(2, reconnectAttempts.current - 1);
          
          reconnectTimeoutRef.current = setTimeout(() => {
            if (shouldReconnectRef.current && enabled) {
              console.log(`[TaskStreaming] Reconnecting (attempt ${reconnectAttempts.current})...`);
              connect();
            }
          }, delay);
        }
      };

      wsRef.current = ws;
    } catch (error) {
      console.error('[TaskStreaming] Failed to connect:', error);
      isConnectingRef.current = false;
    }
  }, [enabled, task_id, chat_id]);

  const disconnect = useCallback(() => {
    shouldReconnectRef.current = false;
    
    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current);
      reconnectTimeoutRef.current = null;
    }
    
    if (wsRef.current) {
      const ws = wsRef.current;
      wsRef.current = null;
      
      if (ws.readyState === WebSocket.CONNECTING || ws.readyState === WebSocket.OPEN) {
        ws.close(1000, 'Intentional disconnect');
      }
    }
    
    reconnectAttempts.current = 0;
    isConnectingRef.current = false;
  }, []);

  useEffect(() => {
    if (enabled && chat_id) {
      shouldReconnectRef.current = true;
      connect();
    } else {
      disconnect();
    }

    return () => {
      disconnect();
    };
  }, [enabled, chat_id, task_id, connect, disconnect]);

  return {
    connected: wsRef.current?.readyState === WebSocket.OPEN,
    disconnect,
    reconnect: () => {
      shouldReconnectRef.current = true;
      reconnectAttempts.current = 0;
      connect();
    }
  };
}
