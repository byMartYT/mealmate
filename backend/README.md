# MealMate Backend

Ein FastAPI-basiertes Backend für die MealMate-App.

## Einrichtung

### Voraussetzungen

- Python 3.9+
- MongoDB Atlas Account

### Installation

1. Virtuelle Umgebung erstellen und aktivieren:

```bash
# Im backend-Ordner
python3 -m venv venv
source venv/bin/activate  # Unter Windows: venv\Scripts\activate
```

2. Abhängigkeiten installieren:

```bash
pip install -r requirements.txt
```

3. Umgebungsvariablen für MongoDB Atlas konfigurieren:
   Bearbeite die `.env`-Datei im backend-Ordner mit deinen MongoDB Atlas-Zugangsdaten:

```
MONGODB_URL=mongodb+srv://username:password@cluster-name.mongodb.net
DB_NAME=mealmate
```

So erhältst du die MongoDB Atlas-Verbindungs-URL:

- Logge dich in dein [MongoDB Atlas-Konto](https://cloud.mongodb.com/) ein
- Gehe zu deinem Cluster und klicke auf "Connect"
- Wähle "Connect your application"
- Kopiere den Connection String und ersetze `<username>`, `<password>` und ggf. `<dbname>` mit deinen Werten

### Beispieldaten laden

Führen Sie folgendes Skript aus, um Beispielrezepte in die Datenbank zu laden:

```bash
python seed.py
```

## Server starten

Führen Sie den folgenden Befehl aus, um den Entwicklungsserver zu starten:

```bash
python -m uvicorn main:app --reload
```

Der Server wird unter http://127.0.0.1:8000 gestartet.

## API-Dokumentation

Nach dem Start des Servers ist die API-Dokumentation unter folgenden URLs verfügbar:

- Swagger UI: http://127.0.0.1:8000/docs
- ReDoc: http://127.0.0.1:8000/redoc

## Endpunkte

### Rezepte

- `GET /recipes` - Liste aller Rezepte mit Filterung
- `GET /recipes/{recipe_id}` - Einzelnes Rezept abrufen
- `POST /recipes` - Neues Rezept erstellen
- `PUT /recipes/{recipe_id}` - Rezept aktualisieren
- `DELETE /recipes/{recipe_id}` - Rezept löschen

### Weitere Endpunkte

- `GET /categories` - Liste aller Kategorien
- `GET /areas` - Liste aller Herkunftsregionen
- `GET /search?q={query}` - Rezepte durchsuchen

## Integration mit Flutter

Um dieses Backend mit der Flutter-App zu verbinden, verwenden Sie die entsprechenden HTTP-Anfragen aus Ihrem Flutter-Code. Wenn Sie lokal entwickeln, stellen Sie sicher, dass die App auf den korrekten URL zugreift (z.B. http://10.0.2.2:8000 für Android-Emulatoren).
