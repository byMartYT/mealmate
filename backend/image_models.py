from pydantic import BaseModel, Field
from typing import List, Optional

class ImageUpload(BaseModel):
    """Modell für den Upload von Base64-codierten Bildern"""
    images: List[str] = Field(..., description="Liste von Base64-codierten Bildern")
    
class ImageResponse(BaseModel):
    """Antwortmodell für hochgeladene Bilder"""
    success: bool = Field(..., description="Gibt an, ob der Upload erfolgreich war")
    message: str = Field(..., description="Statusmeldung")
    image_urls: Optional[List[str]] = Field(None, description="URLs der hochgeladenen Bilder")
    error: Optional[str] = Field(None, description="Fehlermeldung bei Misserfolg")
