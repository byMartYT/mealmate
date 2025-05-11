from pydantic import BaseModel, Field, HttpUrl, validator
from typing import List, Optional, Union
from bson import ObjectId
from datetime import datetime

class PyObjectId(ObjectId):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v):
        if not ObjectId.is_valid(v):
            raise ValueError("Invalid ObjectId")
        return ObjectId(v)

    @classmethod
    def __modify_schema__(cls, field_schema):
        field_schema.update(type="string")

class Ingredient(BaseModel):
    name: str
    measure: str

class RecipeBase(BaseModel):
    title: str
    instructions: List[str]
    ingredients: List[Ingredient]
    cookingTime: Optional[str] = None
    servings: Optional[str] = None
    category: Optional[str] = None
    area: Optional[str] = None
    image: Optional[HttpUrl] = None
    tags: Optional[List[str]] = []
    youtube: Optional[str] = None  # Änderung von HttpUrl zu str
    idMeal: Optional[str] = None

    @validator('youtube', pre=True)
    def validate_youtube_url(cls, v):
        if v is None or v == "":
            return None
        # Einfache Überprüfung, ob es sich um eine YouTube-URL handelt
        if v and isinstance(v, str) and "youtube.com" in v:
            return v
        if v and isinstance(v, str) and "youtu.be" in v:
            return v
        try:
            # Versuche zu überprüfen, ob es eine gültige URL ist
            HttpUrl.validate(v)
            return v
        except:
            # Wenn nicht, gebe None zurück anstatt einen Fehler zu werfen
            return None

class RecipeCreate(RecipeBase):
    pass

class RecipeUpdate(BaseModel):
    title: Optional[str] = None
    instructions: Optional[List[str]] = None
    ingredients: Optional[List[Ingredient]] = None
    cookingTime: Optional[str] = None
    servings: Optional[str] = None
    category: Optional[str] = None
    area: Optional[str] = None
    image: Optional[HttpUrl] = None
    tags: Optional[List[str]] = None
    youtube: Optional[HttpUrl] = None

class RecipeInDB(RecipeBase):
    id: str = Field(default_factory=str, alias="_id")
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)

    class Config:
        allow_population_by_field_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}

class Recipe(RecipeBase):
    id: str = Field(..., alias="_id")

    class Config:
        allow_population_by_field_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}
