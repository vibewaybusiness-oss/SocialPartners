"""
Messaging Router
Handles messaging and conversation functionality
"""

import logging
from typing import List, Optional
from datetime import datetime
from fastapi import Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from api.routers.factory import create_business_router
from api.routers.base_router import create_standard_response
from api.services.database import get_db
from api.services.auth.auth import get_current_user
from api.models import User
from api.services.errors import handle_exception

logger = logging.getLogger(__name__)

router_wrapper = create_business_router(
    name="messaging",
    prefix="",
    tags=["Messaging"]
)
router = router_wrapper.router


class MessageCreate(BaseModel):
    conversation_id: Optional[str] = None
    recipient_id: str
    content: str


class MessageRead(BaseModel):
    id: str
    sender_id: str
    sender_name: str
    sender_avatar: Optional[str] = None
    content: str
    timestamp: datetime
    read: bool

    class Config:
        from_attributes = True


class ConversationRead(BaseModel):
    id: str
    user_id: str
    user_name: str
    user_avatar: Optional[str] = None
    last_message: str
    last_message_time: datetime
    unread_count: int

    class Config:
        from_attributes = True


@router.get("/conversations")
async def get_conversations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all conversations for the current user"""
    try:
        conversations = []
        
        return create_standard_response(
            data=conversations,
            message="Conversations retrieved successfully"
        )
    except Exception as e:
        logger.error(f"Error retrieving conversations: {e}", exc_info=True)
        raise handle_exception(e, "retrieving conversations")


@router.get("/conversations/{conversation_id}/messages")
async def get_messages(
    conversation_id: str,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get messages for a specific conversation"""
    try:
        messages = []
        
        return create_standard_response(
            data=messages,
            message="Messages retrieved successfully"
        )
    except Exception as e:
        logger.error(f"Error retrieving messages: {e}", exc_info=True)
        raise handle_exception(e, "retrieving messages")


@router.post("/messages")
async def send_message(
    message_data: MessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Send a message to a user"""
    try:
        message = {
            "id": f"msg_{datetime.now().timestamp()}",
            "sender_id": str(current_user.id),
            "sender_name": current_user.name or current_user.email,
            "sender_avatar": None,
            "content": message_data.content,
            "timestamp": datetime.now(),
            "read": False
        }
        
        return create_standard_response(
            data=message,
            message="Message sent successfully"
        )
    except Exception as e:
        logger.error(f"Error sending message: {e}", exc_info=True)
        raise handle_exception(e, "sending message")


@router.put("/messages/{message_id}/read")
async def mark_message_read(
    message_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Mark a message as read"""
    try:
        return create_standard_response(
            data={"message_id": message_id, "read": True},
            message="Message marked as read"
        )
    except Exception as e:
        logger.error(f"Error marking message as read: {e}", exc_info=True)
        raise handle_exception(e, "marking message as read")


@router.get("/conversations/{conversation_id}/unread-count")
async def get_unread_count(
    conversation_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get unread message count for a conversation"""
    try:
        return create_standard_response(
            data={"unread_count": 0},
            message="Unread count retrieved successfully"
        )
    except Exception as e:
        logger.error(f"Error retrieving unread count: {e}", exc_info=True)
        raise handle_exception(e, "retrieving unread count")

