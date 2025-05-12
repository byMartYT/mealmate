from pydantic import BaseModel, Field
from typing import List, Optional

class IngredientItem(BaseModel):
    """Modell für eine erkannte Zutat"""
    name: str = Field(..., description="Name der Zutat")
    amount: Optional[str] = Field(None, description="Menge der Zutat (falls erkannt)")
    unit: Optional[str] = Field(None, description="Einheit der Zutat (falls erkannt)")
    
class IngredientsResponse(BaseModel):
    """Antwortmodell nach der Analyse eines Kühlschrankfotos"""
    success: bool = Field(..., description="Gibt an, ob die Analyse erfolgreich war")
    message: str = Field(..., description="Statusmeldung")
    ingredients: List[IngredientItem] = Field([], description="Liste der erkannten Zutaten")
    error: Optional[str] = Field(None, description="Fehlermeldung bei Misserfolg")
