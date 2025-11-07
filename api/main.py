#!/usr/bin/env python3
"""
SocialPartners FastAPI Main Application - Sophisticated Router Architecture
Uses middleware-based authentication and security with organized router management
"""

import asyncio
import os
import traceback
from contextlib import asynccontextmanager

import uvicorn
from dotenv import load_dotenv
from fastapi import FastAPI, Request, HTTPException
from typing import Dict, Any
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from starlette.middleware.base import BaseHTTPMiddleware

# Load environment variables from .env file
load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

from api.config.settings import settings

# Import middleware
from api.middleware.sanitizer_middleware import SanitizerMiddleware, SanitizationConfig, SanitizationLevel
from api.middleware.error_middleware import setup_error_handlers
from api.middleware.rate_limiting_middleware import RateLimitingMiddleware, RateLimitConfig
from api.middleware.security_headers_middleware import SecurityHeadersMiddleware, SecurityHeadersConfig
from api.middleware.monitoring_middleware import MonitoringMiddleware, MonitoringConfig
from api.middleware.auth_middleware import AuthMiddleware, AuthMiddlewareConfig
from api.middleware.localhost_logging_middleware import LocalhostLoggingMiddleware

# Import router architecture
from api.routers import (
    # Architecture and registry
    get_router_registry,
    register_router,
    register_all_routers_with_app,
    validate_router_registry,
    get_router_registry_summary,
    # Router instances
    auth_router,
    project_router,
    credits_router,
    payment_router,
    export_router,
    particle_router,
    visualizer_router,
    stats_router,
    social_media_router,
    automation_router,
    backend_storage_router,
)

# Import additional routers
from api.routers.admin.stripe_admin_router import router as stripe_admin_router
from api.routers.admin.credits_admin import router as credits_admin_router
from api.routers.admin.database_router import router as database_admin_router
from api.routers.admin.database_data_router import router as database_data_router
from api.routers.workflows import router as workflows_router
from api.routers.health_router import router as health_router

# Import services for initialization
# from api.services.sanitization import SanitizerConfig as MediaSanitizerConfig  # Module not found


class LargeBodyMiddleware(BaseHTTPMiddleware):
    """Middleware to handle large request bodies"""

    def __init__(self, app, max_body_size: int = 100 * 1024 * 1024):  # 100MB default
        super().__init__(app)
        self.max_body_size = max_body_size

    async def dispatch(self, request: Request, call_next):
        # Check content length if available
        content_length = request.headers.get("content-length")
        if content_length and int(content_length) > self.max_body_size:
            return JSONResponse(status_code=413, content={"error": "Payload Too Large", "max_size": self.max_body_size})

        # Read the body to prevent uvicorn's default 1MB limit
        try:
            body = await request.body()
            if len(body) > self.max_body_size:
                return JSONResponse(
                    status_code=413, content={"error": "Payload Too Large", "max_size": self.max_body_size}
                )
            # Store the body for later use
            request._body = body
        except Exception as e:
            return JSONResponse(
                status_code=500,
                content={"error": "Internal server error", "detail": str(e)})

        response = await call_next(request)
        return response


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    # Startup
    print("🚀 Starting SocialPartners API with sophisticated architecture...")

    # Initialize database tables
    try:
        from api.services.database import create_tables
        create_tables()
        print("✅ Database tables created/verified")
    except Exception as e:
        print(f"⚠️ Database table creation failed: {e}")

    # Queue manager removed

    # Validate router architecture
    try:
        issues = validate_router_registry()
        if issues:
            print(f"⚠️ Router validation issues found: {issues}")
        else:
            print("✅ Router architecture validation passed")
    except Exception as e:
        print(f"⚠️ Router validation failed: {e}")

    yield
    
    print("🛑 Shutting down SocialPartners API...")


def register_all_routers():
    """Register all routers with the registry"""
    registry = get_router_registry()
    
    # Register routers with their configurations (only those that are imported)
    registry.register_router("auth", auth_router)
    registry.register_router("projects", project_router)
    registry.register_router("credits", credits_router)
    registry.register_router("payments", payment_router)
    
    registry.register_router("exports", export_router)
    registry.register_router("particles", particle_router)
    registry.register_router("visualizers", visualizer_router)
    registry.register_router("stats", stats_router)
    registry.register_router("social_media", social_media_router)
    registry.register_router("automation", automation_router)
    registry.register_router("storage", backend_storage_router)
    registry.register_router("admin_credits", credits_admin_router)
    registry.register_router("admin_stripe", stripe_admin_router)
    registry.register_router("admin_database", database_admin_router)
    registry.register_router("admin_database_data", database_data_router)
    registry.register_router("workflows", workflows_router)
    
    print("✅ All routers registered with registry")


def validate_router_architecture():
    """Validate router architecture and report issues"""
    try:
        issues = validate_router_registry()
        if issues:
            print("⚠️ Router architecture validation issues:")
            for router_name, router_issues in issues.items():
                print(f"  - {router_name}: {router_issues}")
        else:
            print("✅ Router architecture validation passed")
        
        # Print router summary
        summary = get_router_registry_summary()
        print(f"📊 Router Summary: {summary['total_registered']} routers registered")
        print(f"📊 Categories: {summary['categories']}")
        print(f"📊 Priorities: {summary['priorities']}")
        
        return issues
    except Exception as e:
        print(f"❌ Router validation failed: {e}")
        return {"validation_error": [str(e)]}


# Register all routers with the registry BEFORE app creation
try:
    register_all_routers()
    print("✅ All routers registered with sophisticated architecture")
except Exception as e:
    print(f"⚠️ Router registration failed: {e}")

# Create FastAPI app with sophisticated configuration
app = FastAPI(
    title="SocialPartners API - Sophisticated Architecture",
    description="Social media collaboration and content management platform with sophisticated router architecture",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan
)

# Middleware configuration - CORS + Auth for proper authentication
print("✅ Using CORS + Auth middleware for proper authentication")

# CORS middleware - required for frontend communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins if hasattr(settings, 'cors_origins') else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Auth middleware - required for protected endpoints
auth_config = AuthMiddlewareConfig(
    public_paths=[
        "/health", 
        "/docs", 
        "/openapi.json", 
        "/redoc", 
        "/metrics",
        "/api/auth/google",
        "/api/auth/google/callback",
        "/api/auth/github",
        "/api/auth/github/callback",
        "/api/auth/youtube/callback",
        "/api/auth/register",
        "/api/auth/login",
        "/api/auth/refresh",
        "/api/credits/pricing/calculate-budget",
    ],
    skip_methods=["GET", "HEAD", "OPTIONS"],
    log_auth_attempts=True
)
app.add_middleware(AuthMiddleware, config=auth_config)

app.add_middleware(LocalhostLoggingMiddleware)

register_all_routers_with_app(app)
print("✅ All routers included in FastAPI app")

@app.get("/")
async def root():
    """Root endpoint with sophisticated architecture information"""
    return {
        "message": "SocialPartners API - Sophisticated Architecture",
        "version": "2.0.0",
        "architecture": "sophisticated",
        "features": [
            "Middleware-based authentication",
            "Automatic input sanitization",
            "Rate limiting and abuse protection",
            "Security headers",
            "Comprehensive monitoring",
            "Organized router architecture",
            "Priority-based registration",
            "Automatic error handling"
        ],
        "endpoints": {
            "docs": "/docs",
            "health": "/health",
            "metrics": "/metrics"
        },
        "router_summary": get_router_registry_summary()
    }


# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint - Auto-reload test"""
    return {
        "status": "healthy",
        "architecture": "sophisticated",
        "version": "2.0.0",
        "timestamp": "2024-01-01T00:00:00Z",
        "auto_reload": "enabled"
    }


if __name__ == "__main__":
    uvicorn.run(
        "api.main:app",
        host="localhost",
        port=8000,
        reload=True,
        log_level="info"
    )