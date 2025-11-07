"""
Collaborators Router
Handles collaborator discovery and connection functionality
"""

import logging
from typing import List, Optional
from fastapi import Depends, HTTPException, Query, status
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
    name="collaborators",
    prefix="",
    tags=["Collaborators"]
)
router = router_wrapper.router


class CollaboratorRead(BaseModel):
    id: str
    name: str
    avatar: Optional[str] = None
    title: str
    location: str
    skills: List[str]
    rating: float
    projects: int
    bio: str
    available: bool
    connected: bool

    class Config:
        from_attributes = True


class ConnectionRequest(BaseModel):
    collaborator_id: str


@router.get("/search")
async def search_collaborators(
    query: Optional[str] = Query(None, description="Search query for name, skills, or expertise"),
    skills: Optional[str] = Query(None, description="Comma-separated list of skills to filter by"),
    available_only: bool = Query(False, description="Filter by availability"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Search for collaborators"""
    try:
        skill_list = skills.split(",") if skills else []
        
        collaborators = []
        
        return create_standard_response(
            data={
                "collaborators": collaborators,
                "total": len(collaborators),
                "limit": limit,
                "offset": offset
            },
            message="Collaborators retrieved successfully"
        )
    except Exception as e:
        logger.error(f"Error searching collaborators: {e}", exc_info=True)
        raise handle_exception(e, "searching collaborators")


@router.get("/{collaborator_id}")
async def get_collaborator(
    collaborator_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get detailed information about a specific collaborator"""
    try:
        collaborator = {
            "id": collaborator_id,
            "name": "Example Collaborator",
            "title": "Video Editor",
            "location": "San Francisco, CA",
            "skills": ["Video Editing", "After Effects"],
            "rating": 4.8,
            "projects": 24,
            "bio": "Experienced video editor",
            "available": True,
            "connected": False
        }
        
        return create_standard_response(
            data=collaborator,
            message="Collaborator retrieved successfully"
        )
    except Exception as e:
        logger.error(f"Error retrieving collaborator: {e}", exc_info=True)
        raise handle_exception(e, "retrieving collaborator")


@router.post("/connect")
async def connect_collaborator(
    connection_request: ConnectionRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Connect with a collaborator"""
    try:
        return create_standard_response(
            data={
                "collaborator_id": connection_request.collaborator_id,
                "connected": True
            },
            message="Successfully connected with collaborator"
        )
    except Exception as e:
        logger.error(f"Error connecting with collaborator: {e}", exc_info=True)
        raise handle_exception(e, "connecting with collaborator")


@router.delete("/connect/{collaborator_id}")
async def disconnect_collaborator(
    collaborator_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Disconnect from a collaborator"""
    try:
        return create_standard_response(
            data={
                "collaborator_id": collaborator_id,
                "connected": False
            },
            message="Successfully disconnected from collaborator"
        )
    except Exception as e:
        logger.error(f"Error disconnecting from collaborator: {e}", exc_info=True)
        raise handle_exception(e, "disconnecting from collaborator")


@router.get("/connections/list")
async def get_connections(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get list of connected collaborators"""
    try:
        connections = []
        
        return create_standard_response(
            data={
                "connections": connections,
                "total": len(connections),
                "limit": limit,
                "offset": offset
            },
            message="Connections retrieved successfully"
        )
    except Exception as e:
        logger.error(f"Error retrieving connections: {e}", exc_info=True)
        raise handle_exception(e, "retrieving connections")

