from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel

from api.schemas.base import BaseSchema


class ExportBase(BaseSchema):
    pass


class ExportCreate(ExportBase):
    pass


class ExportRead(ExportBase):
    id: UUID
    project_id: UUID
    file_path: str
    format: Optional[str] = None
    resolution: Optional[str] = None
    aspect_ratio: Optional[str] = None
    duration: Optional[int] = None
    size_mb: Optional[int] = None
    version: int = 1
    created_at: datetime
