import getpass
import os

from langchain_openai import AzureChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage
import json
import io
from dotenv import load_dotenv
from ingredient_models import IngredientItem, IngredientsResponse
from typing import List, Dict, Any

load_dotenv()
if not os.environ.get('AZURE_OPENAI_API_KEY'):
    raise ValueError("Please set the AZURE_OPENAI_API_KEY environment variable.")

llm = AzureChatOpenAI(
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    azure_deployment=os.environ["AZURE_OPENAI_DEPLOYMENT"],
    api_version=os.environ["AZURE_OPENAI_API_VERSION"],
    api_key=os.environ["AZURE_OPENAI_API_KEY"],
)

def process_image_with_langchain(prompt, base64_image_string, output_format="json"):
    """
    Process a request with text and base64 encoded image using LangChain.
    
    Args:
        prompt: Text prompt from user
        base64_image_string: Base64 encoded image string from frontend
        output_format: 'json'
        
    Returns:
        Parsed response in requested format
    """
    # Prepare system message based on desired output format
    system_message = SystemMessage(
        content=f"You are a helpful assistant. Respond with valid {output_format.upper()} only."
    )
    
    # Prepare the human message with text and image
    human_message = HumanMessage(
        content=[
            {"type": "text", "text": prompt},
            {"type": "image_url", 
             "image_url": {
                "url": f"data:image/jpeg;base64,{base64_image_string}",
                "detail": "high"
             }
            }
        ]
    )
    
    # Invoke the LLM with the messages
    response = llm.invoke([system_message, human_message])
    content = response.content
    
    # Parse the response based on requested format
    if output_format == "json":
        return json.loads(content)
    else:
        return content


def analyze_images(base64_images: List[str]) -> IngredientsResponse:
    """
    Analyzes one or more images and extracts food ingredients.
    
    Args:
        base64_images: List of Base64-encoded images
        
    Returns:
        IngredientsResponse: Response model with detected ingredients
    """
    # If no images are provided, return an error message
    if not base64_images or len(base64_images) == 0:
        return IngredientsResponse(
            success=False,
            message="No images found for analysis",
            error="At least one image is required"
        )
    
    try:
        # We use the first image for analysis
        base64_image = base64_images[0]
        
        # System prompt for ingredient detection
        prompt = """Analyze this image of a refrigerator or kitchen and identify all 
        visible food items and ingredients. If possible, also provide quantities and units.
        
        Answer with a JSON list in the following format:
        [
            {"name": "Ingredient1", "amount": "Quantity1", "unit": "Unit1"},
            {"name": "Ingredient2", "amount": "Quantity2", "unit": "Unit2"},
            ...
        ]
        
        If quantity or unit cannot be determined, omit the corresponding fields.
        Answer ONLY with the JSON list, without additional text."""
        
        # Rufe die LangChain-Funktion auf
        result = process_image_with_langchain(prompt, base64_image)
        
        # Überprüfe ob das Ergebnis eine Liste ist
        if not isinstance(result, list):
            # Wenn nicht, versuche, es als Objekt zu interpretieren
            if isinstance(result, dict) and "ingredients" in result:
                result = result["ingredients"]
            else:
                raise ValueError(f"Ungültiges Antwortformat: {result}")
        
        # Konvertiere die erkannten Zutaten in IngredientItem-Objekte
        ingredients = []
        for item in result:
            if isinstance(item, dict) and "name" in item:
                ingredients.append(IngredientItem(
                    name=item["name"],
                    amount=item.get("amount"),
                    unit=item.get("unit")
                ))
        print(ingredients)
        
        # Create the response
        if ingredients:
            return IngredientsResponse(
                success=True,
                message=f"{len(ingredients)} ingredients detected",
                ingredients=ingredients
            )
        else:
            return IngredientsResponse(
                success=False,
                message="No ingredients detected",
                error="The AI could not identify any food ingredients in the image"
            )
    
    except Exception as e:
        # Return an error message if any error occurs
        return IngredientsResponse(
            success=False,
            message="Error analyzing the images",
            error=str(e)
        )


def generate_recipes(ingredients: List[str]) -> List[str]:
    """
    Generates a list of recipe suggestions based on the given ingredients.
    
    Args:
        ingredients: List of ingredient names
        
    Returns:
        List[str]: A list of recipe names that can be made with the ingredients
    """
    if not ingredients or len(ingredients) == 0:
        return ["No ingredients provided"]
    
    try:
        # Format the ingredient list for the prompt
        ingredients_text = ", ".join(ingredients)
        
        # Create a prompt for recipe generation
        prompt = f"""Given the following ingredients: {ingredients_text}

        Generate a list of 5 recipe titles that can be made with these ingredients.
        You can assume basic pantry items like salt, pepper, oil, common spices, and water are available.
        Focus on practical, well-known recipes that would be simple to make.
        Focus on the main ingredients and create a list of recipes that can be made with them. Dont combinate them into one recipe.
        
        Answer with a JSON array of strings, each string being a recipe title.
        Example: ["Pasta Carbonara", "Mushroom Risotto", ...]
        """
        
        # Call the LLM without an image
        system_message = SystemMessage(
            content="You are a helpful cooking assistant. Respond with valid JSON only."
        )
        
        human_message = HumanMessage(content=prompt)
        
        # Invoke the LLM with the messages
        response = llm.invoke([system_message, human_message])
        content = response.content
        
        print(f"LLM response content: {content}")
        
        # Prüfen, ob der Inhalt leer ist
        if not content or content.isspace():
            print("Error: Received empty content from LLM")
            return ["No recipes found. Please try again with different ingredients."]
            
        # Bereinige den Inhalt von Markdown-Formatierungen
        # Entferne ```json oder ``` am Anfang und Ende der Antwort
        if content.strip().startswith("```"):
            # Finde den Index des ersten Zeilenumbruchs nach den Backticks
            first_line_break = content.find("\n")
            if first_line_break != -1:
                # Entferne die erste Zeile mit den Backticks
                content = content[first_line_break:].strip()
            
            # Entferne auch abschließende Backticks, falls vorhanden
            if content.strip().endswith("```"):
                content = content.strip()[:-3].strip()
                
        print(f"Cleaned recipe JSON content: {content}")
        
        try:
            # Parse the response as JSON
            recipe_list = json.loads(content)
            print(f"Parsed recipe list: {recipe_list}")
            
            # Ensure the result is a list of strings
            if isinstance(recipe_list, list):
                # Take up to 5 recipes
                return recipe_list[:5]
            else:
                print(f"Invalid response format (not a list): {recipe_list}")
                return ["Unable to generate recipes. Please try with different ingredients."]
                
        except json.JSONDecodeError as json_err:
            # If JSON parsing fails, attempt to extract a list from the text
            print(f"JSON parsing error: {json_err}")
            print(f"Attempting to extract recipe list from text: {content}")
            
            # Versuche, die Liste aus dem Text zu extrahieren
            import re
            recipe_matches = re.findall(r'"([^"]+)"', content)
            if recipe_matches:
                print(f"Extracted recipe titles: {recipe_matches}")
                return recipe_matches[:5]
            
            # If all else fails, return an error message
            return ["Error parsing recipes. Please try again."]
            
    except Exception as e:
        # In case of error, return a descriptive message
        print(f"Error generating recipes: {str(e)}")
        return ["Unable to generate recipes. Please try again."]


def generate_recipe_details(recipe_title: str, ingredients: List[str]) -> Dict[str, Any]:
    """
    Generates detailed recipe information based on the recipe title and available ingredients.
    
    Args:
        recipe_title: The name/title of the recipe to generate
        ingredients: List of ingredient names available to the user
        
    Returns:
        Dict: A detailed recipe including ingredients, instructions, cooking time, etc.
    """
    if not recipe_title:
        return {"error": "No recipe title provided"}
    
    try:
        # Format the ingredient list for the prompt
        ingredients_text = ", ".join(ingredients)
        
        # Create a prompt for detailed recipe generation
        prompt = f"""Generate a complete recipe for "{recipe_title}" using these available ingredients: {ingredients_text}.
        You can assume basic pantry items like salt, pepper, oil, common spices, and water are available.
        
        The recipe should be practical and easy to follow for home cooks.
        European measurements are preferred (grams, liters, etc.).
        
        Please format your response as a JSON object with the following structure:
        {{
            "title": "Recipe Title",
            "description": "A brief description of the dish",
            "prepTime": "Preparation time in minutes",
            "cookTime": "Cooking time in minutes",
            "servings": "Number of servings",
            "ingredients": [
                {{"name": "Ingredient 1", "measure": "measure"}},
                {{"name": "Ingredient 2", "measure": "measure"}},
                ...
            ],
            "instructions": [
                "Step 1 instruction",
                "Step 2 instruction",
                ...
            ],
            "tips": "Optional cooking tips"
        }}
        """
        
        # Call the LLM without an image
        system_message = SystemMessage(
            content="You are a professional chef. Respond with valid JSON only."
        )
        
        human_message = HumanMessage(content=prompt)
        
        # Invoke the LLM with the messages
        response = llm.invoke([system_message, human_message])
        content = response.content
        
        print(f"Recipe details LLM response: {content[:500]}...") # Nur die ersten 500 Zeichen für bessere Lesbarkeit
        
        # Prüfen, ob der Inhalt leer ist
        if not content or content.isspace():
            print("Error: Received empty content from LLM when generating recipe details")
            return {
                "title": recipe_title,
                "error": "Empty response from AI service",
                "ingredients": [],
                "instructions": ["Unable to generate recipe instructions. Please try again."]
            }
            
        # Bereinige den Inhalt von Markdown-Formatierungen
        # Entferne ```json oder ``` am Anfang und Ende der Antwort
        if content.strip().startswith("```"):
            # Finde den Index des ersten Zeilenumbruchs nach den Backticks
            first_line_break = content.find("\n")
            if first_line_break != -1:
                # Entferne die erste Zeile mit den Backticks
                content = content[first_line_break:].strip()
            
            # Entferne auch abschließende Backticks, falls vorhanden
            if content.strip().endswith("```"):
                content = content.strip()[:-3].strip()
                
        print(f"Cleaned JSON content: {content[:100]}...") # Die ersten 100 Zeichen der bereinigten Antwort
        
        try:
            # Parse the response as JSON
            recipe_details = json.loads(content)
            print(f"Generated recipe details for: {recipe_title}")
            
            # Stellen Sie sicher, dass alle erforderlichen Felder vorhanden sind
            required_fields = ["title", "ingredients", "instructions"]
            for field in required_fields:
                if field not in recipe_details:
                    recipe_details[field] = [] if field in ["ingredients", "instructions"] else recipe_title
            
            return recipe_details
                
        except json.JSONDecodeError as json_err:
            # If JSON parsing fails, create a minimal recipe with the error
            print(f"JSON parsing error in recipe details: {json_err}")
            
            # Versuche, zumindest die Anweisungen aus dem Text zu extrahieren
            instructions = []
            if "1." in content or "Step 1" in content:
                # Versuche, die Anweisungen zu extrahieren
                import re
                steps = re.split(r'\d+\.|\nStep \d+:', content)
                if len(steps) > 1:
                    instructions = [step.strip() for step in steps[1:] if step.strip()]
            
            return {
                "title": recipe_title,
                "error": f"Error parsing recipe details: {str(json_err)}",
                "description": "We had trouble formatting this recipe properly.",
                "ingredients": [],
                "instructions": instructions if instructions else ["Unable to generate recipe instructions. Please try again."]
            }
            
    except Exception as e:
        # In case of error, return a descriptive error message
        error_msg = f"Error generating recipe details: {str(e)}"
        print(error_msg)
        return {
            "title": recipe_title,
            "error": error_msg,
            "ingredients": [],
            "instructions": ["Unable to generate recipe instructions. Please try again."]
        }

