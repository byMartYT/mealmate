from pydantic import BaseModel, Field
from typing import List, Optional

class IngredientItem(BaseModel):
    """Model for a detected ingredient"""
    name: str = Field(..., description="Name of the ingredient")
    amount: Optional[str] = Field(None, description="Amount of the ingredient (if detected)")
    unit: Optional[str] = Field(None, description="Unit of the ingredient (if detected)")
    
class IngredientsResponse(BaseModel):
    """Response model after analyzing a refrigerator photo"""
    success: bool = Field(..., description="Indicates whether the analysis was successful")
    message: str = Field(..., description="Status message")
    ingredients: List[IngredientItem] = Field([], description="List of detected ingredients")
    error: Optional[str] = Field(None, description="Error message in case of failure")
