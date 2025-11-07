from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel

from api.schemas.base import BaseSchema


class SocialAccountBase(BaseSchema):
    platform: str
    account_name: Optional[str] = None
    account_id: Optional[str] = None


class SocialAccountCreate(SocialAccountBase):
    access_token: str
    refresh_token: Optional[str] = None
    expires_at: Optional[datetime] = None


class SocialAccountRead(SocialAccountBase):
    id: UUID
    user_id: UUID
    account_name: Optional[str] = None
    account_id: Optional[str] = None
    expires_at: Optional[datetime] = None
    created_at: datetime
