from datetime import datetime
from typing import Any, Dict, Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field

from api.schemas.base import BaseSchema


class UserBase(BaseSchema):
    email: EmailStr
    username: Optional[str] = None


class UserCreate(UserBase):
    password: Optional[str] = None


class UserUpdate(BaseSchema):
    username: Optional[str] = None
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    is_active: Optional[bool] = None
    settings: Optional[Dict[str, Any]] = None


class UserRead(UserBase):
    id: UUID
    username: Optional[str] = None
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    is_active: bool
    is_admin: bool
    is_verified: bool
    plan: str = "free"
    billing_id: Optional[str] = None
    total_projects: str = "0"
    storage_used_bytes: str = "0"
    credits_balance: int = 60
    total_credits_earned: int = 60
    total_credits_spent: int = 0
    settings: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    last_login: Optional[datetime] = None


class UserLogin(BaseSchema):
    email: EmailStr
    password: str


class Token(BaseSchema):
    access_token: str
    token_type: str = "bearer"
