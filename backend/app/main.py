from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import settings
from .db import init_schema
from .routers.spatial import router as spatial_router


@asynccontextmanager
async def lifespan(_: FastAPI):
    try:
        init_schema()
    except Exception as exc:
        print(f"schema init skipped: {exc}")
    yield


app = FastAPI(title=settings.app_name, version="0.1.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(spatial_router, prefix="/v1")


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "service": "crosssafe"}
