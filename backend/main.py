from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
from bson import ObjectId
from typing import List, Optional
import os
from dotenv import load_dotenv
from models import Recipe, RecipeInDB, RecipeCreate, RecipeUpdate

# Lade die Umgebungsvariablen
load_dotenv()

app = FastAPI(
    title="MealMate API",
    description="API für die MealMate-App, die Rezepte verwaltet",
    version="1.0.0"
)

# CORS-Einstellungen
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Im Produktivbetrieb spezifische Origins angeben
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# MongoDB-Verbindungseinstellungen
MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DB_NAME = os.getenv("DB_NAME", "mealmate")

# MongoDB-Verbindung
@app.on_event("startup")
async def startup_db_client():
    app.mongodb_client = AsyncIOMotorClient(MONGODB_URL)
    app.mongodb = app.mongodb_client[DB_NAME]

@app.on_event("shutdown")
async def shutdown_db_client():
    app.mongodb_client.close()

# Endpunkte für Rezepte
@app.get("/recipes", response_model=List[Recipe])
async def get_recipes(
    skip: int = 0, 
    limit: int = 10,
    search: Optional[str] = None,
    category: Optional[str] = None,
    area: Optional[str] = None,
    sort_by: Optional[str] = None,
    sort_dir: Optional[str] = "asc"
):
    """
    Holt eine Liste von Rezepten mit gleichzeitiger Filterung, Sortierung und Paginierung.
    
    - search: Suchbegriff der in Titel oder Tags vorkommen soll
    - category: Nach Kategorie filtern (z.B. Seafood, Pasta)
    - area: Nach Herkunftsregion filtern (z.B. Greek, Italian)
    - sort_by: Sortierfeld (title, cookingTime, servings)
    - sort_dir: Sortierrichtung (asc, desc)
    """
    query = {}
    
    if search:
        # Erweitertes Suchfeld, das auch Zutaten durchsucht
        query["$or"] = [
            {"title": {"$regex": search, "$options": "i"}},
            {"tags": {"$regex": search, "$options": "i"}},
            {"ingredients.name": {"$regex": search, "$options": "i"}}
        ]
    
    if category:
        query["category"] = {"$regex": category, "$options": "i"}
    
    if area:
        query["area"] = {"$regex": area, "$options": "i"}
    
    # Sortieroption vorbereiten
    sort_options = {}
    if sort_by:
        # 1 für aufsteigend, -1 für absteigend
        sort_direction = 1 if sort_dir.lower() == "asc" else -1
        sort_options = {sort_by: sort_direction}
    
    # Finde Rezepte mit Sortierung, wenn angegeben
    cursor = app.mongodb["recipes"].find(query)
    
    if sort_options:
        cursor = cursor.sort(list(sort_options.items()))
    
    recipes = await cursor.skip(skip).limit(limit).to_list(limit)
    
    # Konvertiere ObjectId zu String
    for recipe in recipes:
        recipe["_id"] = str(recipe["_id"])
    
    return recipes

@app.get("/recipes/{recipe_id}", response_model=Recipe)
async def get_recipe(recipe_id: str):
    """
    Holt ein einzelnes Rezept anhand seiner ID.
    """
    # Versuche zuerst mit ObjectId
    try:
        recipe = await app.mongodb["recipes"].find_one({"_id": ObjectId(recipe_id)})
    except:
        # Falls die ID kein gültiges ObjectId ist, versuche mit der String-ID
        recipe = await app.mongodb["recipes"].find_one({"idMeal": recipe_id})
    
    if recipe:
        recipe["_id"] = str(recipe["_id"])
        return recipe
    
    raise HTTPException(status_code=404, detail=f"Rezept mit ID {recipe_id} nicht gefunden")



# Weitere Endpunkte
@app.get("/categories")
async def get_categories():
    """
    Liefert alle verfügbaren Kategorien.
    """
    categories = await app.mongodb["recipes"].distinct("category")
    return {"categories": categories}

@app.get("/areas")
async def get_areas():
    """
    Liefert alle verfügbaren Herkunftsregionen.
    """
    areas = await app.mongodb["recipes"].distinct("area")
    return {"areas": areas}

@app.get("/search")
async def search_recipes(
    q: str = Query(..., min_length=1),
    skip: int = 0,
    limit: int = 10,
    category: Optional[str] = None,
    area: Optional[str] = None,
    sort_by: Optional[str] = None,
    sort_dir: Optional[str] = "asc"
):
    """
    Durchsucht Rezepte nach einem Suchbegriff mit gleichzeitiger Filterung und Sortierung.
    
    - q: Der Suchbegriff
    - category: Nach Kategorie filtern
    - area: Nach Herkunftsregion filtern
    - sort_by: Sortierfeld (title, cookingTime, servings)
    - sort_dir: Sortierrichtung (asc, desc)
    """
    query = {
        "$or": [
            {"title": {"$regex": q, "$options": "i"}},
            {"tags": {"$regex": q, "$options": "i"}},
            {"ingredients.name": {"$regex": q, "$options": "i"}},
            {"category": {"$regex": q, "$options": "i"}},
            {"area": {"$regex": q, "$options": "i"}}
        ]
    }
    
    # Füge weitere Filter hinzu, wenn angegeben
    if category:
        query["category"] = {"$regex": category, "$options": "i"}
    
    if area:
        query["area"] = {"$regex": area, "$options": "i"}
    
    # Sortieroption vorbereiten
    sort_options = {}
    if sort_by:
        # 1 für aufsteigend, -1 für absteigend
        sort_direction = 1 if sort_dir.lower() == "asc" else -1
        sort_options = {sort_by: sort_direction}
    
    # Finde Rezepte mit Sortierung, wenn angegeben
    cursor = app.mongodb["recipes"].find(query)
    
    if sort_options:
        cursor = cursor.sort(list(sort_options.items()))
    
    recipes = await cursor.skip(skip).limit(limit).to_list(limit)
    
    # Konvertiere ObjectId zu String
    for recipe in recipes:
        recipe["_id"] = str(recipe["_id"])
    
    total = await app.mongodb["recipes"].count_documents(query)
    
    return {
        "total": total,
        "recipes": recipes
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
