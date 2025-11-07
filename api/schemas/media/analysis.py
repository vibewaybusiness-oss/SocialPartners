from typing import Any, Dict, Optional
from uuid import UUID

from pydantic import BaseModel

from api.schemas.base import BaseSchema


class AnalysisResponse(BaseSchema):
    track_id: Optional[UUID] = None
    video_id: Optional[UUID] = None
    image_id: Optional[UUID] = None
    analysis: Dict[str, Any]
    description: Optional[str] = None
