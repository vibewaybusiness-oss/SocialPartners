from datetime import datetime
from typing import Any, Dict, Optional
from uuid import UUID

from pydantic import BaseModel

from api.schemas.base import BaseSchema


class ImageBase(BaseSchema):
    prompt: Optional[str] = None


class ImageCreate(ImageBase):
    pass


class ImageRead(ImageBase):
    id: UUID
    project_id: UUID
    file_path: str
    type: str
    prompt: Optional[str] = None
    prompt_number: Optional[int] = None
    format: Optional[str] = None
    resolution: Optional[str] = None
    size_mb: Optional[int] = None
    image_metadata: Optional[Dict[str, Any]] = None
    created_at: datetime
