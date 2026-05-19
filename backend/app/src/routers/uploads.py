import uuid
from typing import Annotated, Literal

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from src.dependencies import get_current_user
from src.models.user import User
from src.services.minio_service import generate_presigned_put_url

router = APIRouter(prefix="/uploads", tags=["uploads"])


class PresignedUrlRequest(BaseModel):
    filename: str
    content_type: str = "image/jpeg"
    purpose: Literal["post", "avatar", "group"] = "post"


class PresignedUrlResponse(BaseModel):
    upload_url: str
    object_key: str


@router.post("/presigned-url", response_model=PresignedUrlResponse)
async def get_presigned_url(
    body: PresignedUrlRequest,
    current_user: Annotated[User, Depends(get_current_user)],
):
    ext = body.filename.rsplit(".", 1)[-1].lower() if "." in body.filename else "jpg"
    object_key = f"{body.purpose}/{current_user.id}/{uuid.uuid4()}.{ext}"
    upload_url = generate_presigned_put_url(object_key, body.content_type)
    return PresignedUrlResponse(upload_url=upload_url, object_key=object_key)
