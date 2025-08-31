import datetime
import logging
from uuid import uuid4

from app.config import DEFAULT_APP_ID, USER_ID
from app.database import Base, SessionLocal, engine
from app.mcp_server import setup_mcp_server
from app.models import App, User
from app.routers import apps_router, config_router, memories_router, stats_router
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi_pagination import add_pagination
import os
import socket
from contextlib import closing

logging.basicConfig(level=logging.INFO)
logging.info("Starting application module import (api.main)...")

app = FastAPI(title="OpenMemory API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create all tables
Base.metadata.create_all(bind=engine)

# Check for USER_ID and create default user if needed
def create_default_user():
    db = SessionLocal()
    try:
        # Check if user exists
        user = db.query(User).filter(User.user_id == USER_ID).first()
        if not user:
            # Create default user
            user = User(
                id=uuid4(),
                user_id=USER_ID,
                name="Default User",
                created_at=datetime.datetime.now(datetime.UTC)
            )
            db.add(user)
            db.commit()
    finally:
        db.close()


def create_default_app():
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.user_id == USER_ID).first()
        if not user:
            return

        # Check if app already exists
        existing_app = db.query(App).filter(
            App.name == DEFAULT_APP_ID,
            App.owner_id == user.id
        ).first()

        if existing_app:
            return

        app = App(
            id=uuid4(),
            name=DEFAULT_APP_ID,
            owner_id=user.id,
            created_at=datetime.datetime.now(datetime.UTC),
            updated_at=datetime.datetime.now(datetime.UTC),
        )
        db.add(app)
        db.commit()
    finally:
        db.close()

# Create default user on startup
create_default_user()
create_default_app()

# Setup MCP server
setup_mcp_server(app)

# Include routers
app.include_router(memories_router)
app.include_router(apps_router)
app.include_router(stats_router)
app.include_router(config_router)

# Add pagination support
add_pagination(app)

# Basic root & health endpoints for platform health checks
@app.get("/")
def root():
    return {"status": "ok", "service": "openmemory", "version": "1"}

@app.get("/healthz")
def healthz():
    # Potential extension: check DB connectivity
    try:
        db = SessionLocal()
        db.execute("SELECT 1")
        db.close()
        db_ok = True
    except Exception:
        db_ok = False
    return {"ok": True, "db": db_ok}

logging.info("Application startup wiring complete (api.main).")


@app.get("/health", tags=["system"])  # Lightweight health endpoint
def health():
    """Basic health check.

    Returns OK plus optional checks:
    - database connectivity (simple session open)
    - qdrant TCP reachability if QDRANT_HOST/PORT set
    """
    status = {"status": "ok"}
    # DB check
    try:
        db = SessionLocal(); db.execute("SELECT 1"); db.close()
        status["database"] = "ok"
    except Exception as e:
        status["database"] = f"error: {e}"; status["status"] = "degraded"

    # Qdrant reachability (shallow TCP check)
    host = os.environ.get("QDRANT_HOST")
    port = os.environ.get("QDRANT_PORT") or ""
    if host and port:
        try:
            with closing(socket.create_connection((host, int(port)), timeout=1.5)):
                status["qdrant"] = "ok"
        except Exception as e:
            status["qdrant"] = f"unreachable: {e}"; status["status"] = "degraded"
    return status
