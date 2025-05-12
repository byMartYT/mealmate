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
        
        # Parse the response as JSON
        recipe_list = json.loads(content)

        print(recipe_list)
        
        # Ensure the result is a list of strings
        if isinstance(recipe_list, list):
            # Take up to 10 recipes
            return recipe_list[:5]
        else:
            raise ValueError(f"Invalid response format: {recipe_list}")
            
    except Exception as e:
        # In case of error, return a descriptive message
        print(f"Error generating recipes: {str(e)}")
        return ["Unable to generate recipes. Please try again."]

