from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from motor.motor_asyncio import AsyncIOMotorClient
from bson import ObjectId
from typing import List, Optional
import os
import base64
from datetime import datetime
from dotenv import load_dotenv
from models import Recipe
from image_models import ImageResponse, ImageUpload
from ingredient_models import IngredientsResponse, IngredientItem
import llm_service
from llm_service import process_image_with_langchain

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
    
    # Erstelle Upload-Verzeichnis, falls es nicht existiert
    UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "uploads")
    os.makedirs(UPLOAD_DIR, exist_ok=True)

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
    pipeline = []
    
    # Kategorie- und Bereichsfilter anwenden (unabhängig vom Suchbegriff)
    if category:
        query["category"] = {"$regex": category, "$options": "i"}
    
    if area:
        query["area"] = {"$regex": area, "$options": "i"}
    
    if search:
        # Wenn ein Suchbegriff vorhanden ist, berechnen wir eine Relevanz
        search_regex = {"$regex": search, "$options": "i"}
        
        # Grundlegende Suche über mehrere Felder
        search_query = {
            "$or": [
                {"title": search_regex},
                {"tags": search_regex},
                {"category": search_regex},
                {"area": search_regex},
                {"ingredients.name": search_regex}
            ]
        }
        
        # Kombiniere Suchfilter mit Kategorie/Bereichsfilter
        if query:
            # Wenn bereits Filter existieren, wende sie zusammen mit der Suche an
            query = {"$and": [query, search_query]}
        else:
            # Wenn keine Filter existieren, verwende nur die Suche
            query = search_query
        
        # Wenn keine Sortierung angegeben wurde, nach Relevanz sortieren
        if not sort_by:
            # Aggregation-Pipeline verwenden, um Relevanz zu berechnen
            pipeline = [
                {"$match": query},
                # Relevanz-Score berechnen basierend auf wo der Suchbegriff vorkommt
                {"$addFields": {
                    "relevanceScore": {
                        "$sum": [
                            # Treffer im Titel haben höchste Priorität
                            {"$cond": [{"$regexMatch": {"input": {"$ifNull": ["$title", ""]}, "regex": search, "options": "i"}}, 10, 0]},
                            # Treffer in Kategorie haben zweithöchste Priorität
                            {"$cond": [{"$regexMatch": {"input": {"$ifNull": ["$category", ""]}, "regex": search, "options": "i"}}, 8, 0]},
                            # Treffer in Herkunftsregion
                            {"$cond": [{"$regexMatch": {"input": {"$ifNull": ["$area", ""]}, "regex": search, "options": "i"}}, 7, 0]},
                            # Treffer in Tags
                            {"$cond": [{"$anyElementTrue": {
                                "$map": {
                                    "input": {"$ifNull": ["$tags", []]},
                                    "as": "tag",
                                    "in": {"$regexMatch": {"input": "$$tag", "regex": search, "options": "i"}}
                                }
                            }}, 5, 0]},
                            # Zählen wie viele Zutaten übereinstimmen (weniger wichtig)
                            {"$size": {"$filter": {
                                "input": {"$ifNull": ["$ingredients", []]},
                                "as": "ingredient",
                                "cond": {"$regexMatch": {"input": "$$ingredient.name", "regex": search, "options": "i"}}
                            }}}
                        ]
                    }
                }},
                {"$sort": {"relevanceScore": -1, "title": 1}},
                {"$skip": skip},
                {"$limit": limit}
            ]
            
            # Aggregations-Pipeline für relevanzbasierte Suche verwenden
            recipes = await app.mongodb["recipes"].aggregate(pipeline).to_list(limit)
        else:
            # Fall back auf normale Suche mit expliziter Sortierung
            cursor = app.mongodb["recipes"].find(query)
            
            # Sortieroption vorbereiten
            sort_options = {}
            # 1 für aufsteigend, -1 für absteigend
            sort_direction = 1 if sort_dir.lower() == "asc" else -1
            sort_options = {sort_by: sort_direction}
            cursor = cursor.sort(list(sort_options.items()))
            
            recipes = await cursor.skip(skip).limit(limit).to_list(limit)
    else:
        # Wenn kein Suchbegriff vorhanden ist, wende nur die Kategorie/Bereichsfilter an (diese wurden bereits oben gesetzt)
        
        # Sortieroption vorbereiten
        cursor = app.mongodb["recipes"].find(query)
        
        if sort_by:
            # 1 für aufsteigend, -1 für absteigend
            sort_direction = 1 if sort_dir.lower() == "asc" else -1
            sort_options = {sort_by: sort_direction}
            cursor = cursor.sort(list(sort_options.items()))
        else:
            # Standardsortierung nach Titel
            cursor = cursor.sort("title", 1)
        
        recipes = await cursor.skip(skip).limit(limit).to_list(limit)
    
    # Konvertiere ObjectId zu String und stelle sicher, dass cookingTime und servings Strings sind
    for recipe in recipes:
        recipe["_id"] = str(recipe["_id"])
        
        # Konvertiere cookingTime zu String, falls es eine Zahl ist
        if "cookingTime" in recipe and not isinstance(recipe["cookingTime"], str):
            recipe["cookingTime"] = f"{recipe['cookingTime']} Min"
            
        # Konvertiere servings zu String, falls es eine Zahl ist
        if "servings" in recipe and not isinstance(recipe["servings"], str):
            recipe["servings"] = f"{recipe['servings']} servings"
    
    return recipes

@app.get('/recipes/highlights', response_model=List[Recipe])
async def get_highlighted_recipes():
    """
    Liefert alle hervorgehobenen Rezepte (mit highlight=True).
    """
    recipes = await app.mongodb["recipes"].find({"highlight": True}).to_list(100)
    
    # Konvertiere ObjectId zu String und stelle sicher, dass cookingTime und servings Strings sind
    for recipe in recipes:
        recipe["_id"] = str(recipe["_id"])
        
        # Konvertiere cookingTime zu String, falls es eine Zahl ist
        if "cookingTime" in recipe and not isinstance(recipe["cookingTime"], str):
            recipe["cookingTime"] = f"{recipe['cookingTime']} Min"
            
        # Konvertiere servings zu String, falls es eine Zahl ist
        if "servings" in recipe and not isinstance(recipe["servings"], str):
            recipe["servings"] = f"{recipe['servings']} servings"
    
    return recipes

@app.get('/recipes/random', response_model=List[Recipe])
async def get_random_recipes(limit: int = 5, category: Optional[str] = None):
    """
    Liefert eine zufällige Auswahl von Rezepten.
    
    - limit: Anzahl der zurückzugebenden Rezepte
    - category: Optional, filtert Rezepte nach Kategorie
    """
    # Die MongoDB-Aggregationspipeline für zufällige Dokumente
    pipeline = []
    
    # Füge einen Match-Filter für die Kategorie hinzu, falls angegeben
    if category:
        pipeline.append({"$match": {"category": {"$regex": category, "$options": "i"}}})
    
    # Füge den Sample-Operator hinzu
    pipeline.append({"$sample": {"size": limit}})
    
    recipes = await app.mongodb["recipes"].aggregate(pipeline).to_list(limit)
    
    # Konvertiere ObjectId zu String und stelle sicher, dass cookingTime und servings Strings sind
    for recipe in recipes:
        recipe["_id"] = str(recipe["_id"])
        
        # Konvertiere cookingTime zu String, falls es eine Zahl ist
        if "cookingTime" in recipe and not isinstance(recipe["cookingTime"], str):
            recipe["cookingTime"] = f"{recipe['cookingTime']} Min"
            
        # Konvertiere servings zu String, falls es eine Zahl ist
        if "servings" in recipe and not isinstance(recipe["servings"], str):
            recipe["servings"] = f"{recipe['servings']} servings"
    
    return recipes

@app.post('/recipes/generate/list', response_model=List[str])
async def generate_recipe_list(ingredients: List[IngredientItem]):
    """
    Generiert eine Liste von Rezepten basierend auf den angegebenen Zutaten.
    
    - ingredients: Liste von Zutaten
    """

    # Konvertiere die Zutaten in ein Format, das vom LLM-Service verarbeitet werden kann
    ingredient_list = [ingredient.name for ingredient in ingredients]
    
    # Verwende den LLM-Service, um Rezepte zu generieren
    recipes = llm_service.generate_recipes(ingredient_list)
    
    return recipes

@app.post('/recipes/generate/details')
async def generate_recipe_details(data: dict):
    """
    Generiert ein detailliertes Rezept basierend auf dem angegebenen Rezepttitel und den verfügbaren Zutaten.
    
    - data: Dictionary mit "recipe_title" und "ingredients"-Liste
    """
    if not data or "recipe_title" not in data or "ingredients" not in data:
        raise HTTPException(status_code=400, detail="Rezepttitel und Zutaten sind erforderlich")
    
    recipe_title = data["recipe_title"]
    ingredients = data["ingredients"]
    
    # Extrahiere nur die Namen der Zutaten, falls vollständige IngredientItems übergeben wurden
    ingredient_list = []
    for ingredient in ingredients:
        if isinstance(ingredient, dict) and "name" in ingredient:
            ingredient_list.append(ingredient["name"])
        else:
            ingredient_list.append(ingredient)
    
    # Verwende den LLM-Service, um ein detailliertes Rezept zu generieren
    recipe_details = llm_service.generate_recipe_details(recipe_title, ingredient_list)
    
    return recipe_details

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
        
        # Konvertiere cookingTime zu String, falls es eine Zahl ist
        if "cookingTime" in recipe and not isinstance(recipe["cookingTime"], str):
            recipe["cookingTime"] = f"{recipe['cookingTime']} Min"
            
        # Konvertiere servings zu String, falls es eine Zahl ist
        if "servings" in recipe and not isinstance(recipe["servings"], str):
            recipe["servings"] = f"{recipe['servings']} servings"
            
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
    # Grundabfrage mit Suchbegriff
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
    
    total = await app.mongodb["recipes"].count_documents(query)
    
    # Entscheide, ob wir nach Relevanz oder einem anderen Feld sortieren
    if not sort_by:
        # Aggregation-Pipeline für Relevanz
        pipeline = [
            {"$match": query},
            # Relevanz-Score berechnen basierend auf wo der Suchbegriff vorkommt
            {"$addFields": {
                "relevanceScore": {
                    "$sum": [
                        # Treffer im Titel haben höchste Priorität
                        {"$cond": [{"$regexMatch": {"input": {"$ifNull": ["$title", ""]}, "regex": q, "options": "i"}}, 10, 0]},
                        # Treffer in Kategorie haben zweithöchste Priorität
                        {"$cond": [{"$regexMatch": {"input": {"$ifNull": ["$category", ""]}, "regex": q, "options": "i"}}, 8, 0]},
                        # Treffer in Herkunftsregion
                        {"$cond": [{"$regexMatch": {"input": {"$ifNull": ["$area", ""]}, "regex": q, "options": "i"}}, 7, 0]},
                        # Treffer in Tags
                        {"$cond": [{"$in": [q, {"$ifNull": ["$tags", []]}]}, 5, 0]},
                        # Zählen wie viele Zutaten übereinstimmen (weniger wichtig)
                        {"$size": {"$filter": {
                            "input": {"$ifNull": ["$ingredients", []]},
                            "as": "ingredient",
                            "cond": {"$regexMatch": {"input": "$$ingredient.name", "regex": q, "options": "i"}}
                        }}}
                    ]
                }
            }},
            {"$sort": {"relevanceScore": -1, "title": 1}},
            {"$skip": skip},
            {"$limit": limit}
        ]
        
        # Aggregations-Pipeline für relevanzbasierte Suche verwenden
        recipes = await app.mongodb["recipes"].aggregate(pipeline).to_list(limit)
    else:
        # Fall back auf normale Suche mit expliziter Sortierung 
        # Sortieroption vorbereiten
        sort_options = {}
        # 1 für aufsteigend, -1 für absteigend
        sort_direction = 1 if sort_dir.lower() == "asc" else -1
        sort_options = {sort_by: sort_direction}
        
        # Finde Rezepte mit Sortierung
        # Finde Rezepte mit Sortierung
        cursor = app.mongodb["recipes"].find(query)
        cursor = cursor.sort(list(sort_options.items()))
        recipes = await cursor.skip(skip).limit(limit).to_list(limit)
    
    # Konvertiere ObjectId zu String und stelle sicher, dass cookingTime und servings Strings sind
    for recipe in recipes:
        recipe["_id"] = str(recipe["_id"])
        
        # Konvertiere cookingTime zu String, falls es eine Zahl ist
        if "cookingTime" in recipe and not isinstance(recipe["cookingTime"], str):
            recipe["cookingTime"] = f"{recipe['cookingTime']} Min"
            
        # Konvertiere servings zu String, falls es eine Zahl ist
        if "servings" in recipe and not isinstance(recipe["servings"], str):
            recipe["servings"] = f"{recipe['servings']} servings"
    
    return {
        "total": total,
        "recipes": recipes
    }


@app.post("/detect-ingredients", response_model=IngredientsResponse)
async def detect_ingredients(upload: ImageUpload):
    """
    Analyzes Base64-encoded images with Azure OpenAI to detect food ingredients.
    
    - Checks if at least one image is provided
    - Analyzes the images with Azure OpenAI
    - Returns a list of detected ingredients
    """
    # Check if images were sent
    if not upload.images or len(upload.images) == 0:
        return IngredientsResponse(
            success=False,
            message="No images found",
            error="At least one image is required"
        )
    
    try:
        
        # Analysiere die Bilder mit Azure OpenAI über den LLM-Service
        ingredients_response = llm_service.analyze_images(upload.images)
        return ingredients_response
        
    except Exception as e:
        return IngredientsResponse(
            success=False,
            message="Fehler bei der Analyse der Bilder",
            error=str(e)
        )
    

    
    
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
