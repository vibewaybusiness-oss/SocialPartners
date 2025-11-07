from datetime import datetime
from typing import Any, Dict, Optional
from uuid import UUID

from pydantic import BaseModel

from api.models.project import ProjectStatus
from api.schemas.base import BaseSchema


class ProjectBase(BaseSchema):
    type: str
    name: Optional[str] = None
    description: Optional[str] = None


class ProjectCreate(ProjectBase):
    pass


class ProjectUpdate(BaseSchema):
    name: Optional[str] = None
    description: Optional[str] = None
    status: Optional[ProjectStatus] = None
    analysis: Optional[Dict[str, Any]] = None
    settings: Optional[Dict[str, Any]] = None


class ProjectRead(ProjectBase):
    id: UUID
    user_id: UUID
    status: ProjectStatus
    analysis: Optional[Dict[str, Any]] = None
    settings: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
