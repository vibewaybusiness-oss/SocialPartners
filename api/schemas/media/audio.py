from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel

from api.schemas.base import BaseSchema


class AudioBase(BaseSchema):
    type: Optional[str] = "voiceover"
    description: Optional[str] = None


class AudioCreate(AudioBase):
    pass


class AudioRead(AudioBase):
    id: UUID
    project_id: UUID
    file_path: str
    type: Optional[str] = None
    description: Optional[str] = None
    duration: Optional[int] = None
    format: Optional[str] = None
    sample_rate: Optional[int] = None
    channels: Optional[int] = None
    bitrate: Optional[int] = None
    size_mb: Optional[int] = None
    created_at: datetime
