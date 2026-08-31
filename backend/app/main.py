from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .config import settings
from .db import database_health
from .routers.municipal import router as municipal_router
from .routers.spatial import router as spatial_router

app = FastAPI(title=settings.app_name, version="0.2.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "X-CrossSafe-Key"],
)
app.include_router(spatial_router, prefix="/v1")
app.include_router(municipal_router, prefix="/v1/municipal")


@app.get("/health")
def health():
    try:
        dependency_status = database_health()
    except Exception as exc:
        return JSONResponse(
            status_code=503,
            content={
                "status": "degraded",
                "service": "crosssafe",
                "database": "unavailable",
                "detail": exc.__class__.__name__,
            },
        )
    return {"status": "ok", "service": "crosssafe", **dependency_status}
