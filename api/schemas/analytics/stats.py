from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel

from api.schemas.base import BaseSchema


class StatsRead(BaseSchema):
    id: UUID
    export_id: UUID
    platform: str
    account_name: Optional[str] = None
    video_url: Optional[str] = None
    views: int = 0
    likes: int = 0
    comments: int = 0
    shares: int = 0
    watch_time: Optional[int] = None
    last_synced: datetime
