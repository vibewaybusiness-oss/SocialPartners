from datetime import datetime
from typing import Any, Dict, Optional
from uuid import UUID

from pydantic import BaseModel

from api.schemas.base import BaseSchema


class VideoBase(BaseSchema):
    prompts: Optional[str] = None


class VideoCreate(VideoBase):
    pass


class VideoRead(VideoBase):
    id: UUID
    project_id: UUID
    file_path: str
    type: str = "draft"
    status: str = "pending"
    prompts: Optional[str] = None
    is_intro_animation: bool = False
    is_outro_animation: bool = False
    animation_duration: Optional[int] = None
    animation_style: Optional[str] = None
    duration: Optional[int] = None
    resolution: Optional[str] = None
    format: Optional[str] = None
    aspect_ratio: Optional[str] = None
    size_mb: Optional[int] = None
    video_metadata: Optional[Dict[str, Any]] = None
    created_at: datetime
