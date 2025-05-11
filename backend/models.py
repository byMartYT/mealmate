from pydantic import BaseModel, Field, HttpUrl
from typing import List, Optional
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
    youtube: Optional[HttpUrl] = None
    idMeal: Optional[str] = None

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
