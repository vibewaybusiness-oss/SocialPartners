"""
Settings Schemas - Pydantic models for user settings
"""

from typing import Any, Dict, List, Optional
from uuid import UUID

from pydantic import BaseModel, Field

from api.schemas.base import BaseSchema


class ProfileSettings(BaseModel):
    name: str = Field(..., description="User's display name")
    email: str = Field(..., description="User's email address")
    bio: Optional[str] = Field(None, description="User's bio")
    website: Optional[str] = Field(None, description="User's website URL")
    location: Optional[str] = Field(None, description="User's location")


class NotificationSettings(BaseModel):
    email_notifications: bool = Field(True, description="Enable email notifications")
    push_notifications: bool = Field(True, description="Enable push notifications")
    marketing_emails: bool = Field(False, description="Enable marketing emails")
    weekly_digest: bool = Field(True, description="Enable weekly digest")
    project_updates: bool = Field(True, description="Enable project update notifications")


class PrivacySettings(BaseModel):
    profile_visibility: str = Field("private", description="Profile visibility setting")
    show_email: bool = Field(False, description="Show email on public profile")
    allow_comments: bool = Field(True, description="Allow comments on videos")
    data_sharing: bool = Field(False, description="Allow data sharing for improvements")
    analytics_tracking: bool = Field(True, description="Enable analytics tracking")
    marketing_emails: bool = Field(False, description="Enable marketing emails")
    profile_discovery: bool = Field(False, description="Allow profile discovery")
    activity_visibility: str = Field("followers", description="Activity visibility setting")


class SecuritySettings(BaseModel):
    two_factor_enabled: bool = Field(False, description="Two-factor authentication enabled")
    login_notifications: bool = Field(True, description="Login notifications enabled")
    session_timeout: int = Field(30, description="Session timeout in minutes")
    api_access: bool = Field(False, description="API access enabled")
    data_export: bool = Field(True, description="Data export enabled")
    account_deletion: bool = Field(False, description="Account deletion enabled")


class PreferencesSettings(BaseModel):
    theme: str = Field("system", description="UI theme preference")
    language: str = Field("en", description="Language preference")
    timezone: str = Field("UTC", description="Timezone preference")
    auto_save: bool = Field(True, description="Auto-save enabled")
    high_quality: bool = Field(True, description="High quality exports enabled")


class BillingSettings(BaseModel):
    plan: str = Field("free", description="Current subscription plan")
    payment_methods: List[Dict[str, Any]] = Field(default_factory=list, description="Payment methods")
    billing_address: Optional[Dict[str, Any]] = Field(None, description="Billing address")
    next_billing_date: Optional[str] = Field(None, description="Next billing date")
    subscription_status: str = Field("active", description="Subscription status")


class UserSettingsCreate(BaseSchema):
    user_id: UUID
    type: str
    settings: Optional[Dict[str, Any]] = None


class UserSettingsUpdate(BaseSchema):
    settings: Optional[Dict[str, Any]] = None


class UserSettingsResponse(BaseSchema):
    id: UUID
    user_id: UUID
    type: str
    settings: Optional[Dict[str, Any]] = None


class DefaultSettings(BaseSchema):
    type: str
    settings: Optional[Dict[str, Any]] = None
