from datetime import datetime
from typing import Any, Dict, Optional
from uuid import UUID

from pydantic import BaseModel, Field

from api.models.pricing import CreditsTransactionType, PaymentMethod, PaymentStatus
from api.schemas.base import BaseSchema


# PAYMENT SCHEMAS
class PaymentBase(BaseSchema):
    amount_cents: int = Field(..., description="Amount in cents")
    currency: str = Field(default="usd", description="Currency code")
    payment_method: PaymentMethod
    credits_purchased: int = Field(..., description="Number of credits to purchase")
    description: Optional[str] = None
    payment_metadata: Optional[Dict[str, Any]] = None


class PaymentCreate(PaymentBase):
    pass


class PaymentRead(PaymentBase):
    id: UUID
    user_id: UUID
    stripe_payment_intent_id: Optional[str] = None
    stripe_customer_id: Optional[str] = None
    stripe_charge_id: Optional[str] = None
    status: PaymentStatus
    credits_per_dollar: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None


class PaymentIntentCreate(BaseSchema):
    amount_dollars: float = Field(..., ge=1.0, le=1000.0, description="Amount in dollars")
    credits_per_dollar: int = Field(default=100, description="Credits per dollar")
    currency: str = Field(default="usd", description="Currency code")
    payment_method_id: Optional[str] = Field(None, description="Stripe payment method ID")
    description: Optional[str] = None


class PaymentIntentResponse(BaseSchema):
    client_secret: str
    payment_intent_id: str
    amount_cents: int
    credits_purchased: int
    status: str


class PaymentWebhookData(BaseSchema):
    id: str
    object: str
    type: str
    data: Dict[str, Any]
    created: int


# CREDITS/POINTS SCHEMAS
class CreditsTransactionBase(BaseSchema):
    transaction_type: CreditsTransactionType
    amount: int = Field(..., description="Amount of credits (positive for earned/purchased, negative for spent)")
    description: Optional[str] = None
    reference_id: Optional[str] = None
    reference_type: Optional[str] = None


class CreditsTransactionCreate(CreditsTransactionBase):
    pass


class CreditsTransactionRead(CreditsTransactionBase):
    id: UUID
    user_id: UUID
    balance_after: int
    created_at: datetime


class CreditsBalance(BaseSchema):
    current_balance: int
    total_earned: int
    total_spent: int
    recent_transactions: list[CreditsTransactionRead] = []


class CreditsPurchaseRequest(BaseSchema):
    amount_dollars: float = Field(..., ge=1.0, le=1000.0, description="Amount in dollars to spend on credits")
    payment_method_id: Optional[str] = Field(None, description="Stripe payment method ID")


class CreditsSpendRequest(BaseSchema):
    amount: int = Field(..., gt=0, description="Amount of credits to spend")
    description: str = Field(..., description="Description of what the credits are being spent on")
    reference_id: Optional[str] = None
    reference_type: Optional[str] = None
