from typing import Any, Dict, Optional

from pydantic import BaseModel, EmailStr

from api.schemas.base import BaseSchema


class OAuthTokenRequest(BaseSchema):
    code: str
    state: Optional[str] = None


class OAuthUserInfo(BaseSchema):
    id: str
    email: EmailStr
    name: Optional[str] = None
    picture: Optional[str] = None
    provider: str


class OAuthResponse(BaseSchema):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int = 604800
    user: Dict[str, Any]
