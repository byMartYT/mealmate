# MealMate

MealMate ist eine moderne Flutter-App, die dir hilft, Rezepte basierend auf verfügbaren Zutaten zu finden, zu speichern und zu organisieren. Mit integrierter KI-Funktionalität zur Zutatenerkennung aus Fotos und ein benutzerfreundliches Interface für die Rezeptverwaltung.

## 📱 Features

- **Zutatenerkennung per Kamera**: Fotografiere deine Zutaten und lass die KI diese erkennen
- **Rezeptvorschläge**: Bekomme Rezeptvorschläge basierend auf verfügbaren Zutaten
- **Kategoriefilterung**: Durchsuche Rezepte nach verschiedenen Kategorien
- **Favoritenmanagement**: Speichere deine Lieblingsrezepte
- **Einkaufsliste**: Erstelle Einkaufslisten basierend auf ausgewählten Rezepten
- **Dark Mode**: Wähle zwischen hellem und dunklem Design

## 🚀 Einrichtung und Start

### Voraussetzungen

- [Flutter](https://flutter.dev/docs/get-started/install) (Version 3.0+)
- [Docker](https://www.docker.com/products/docker-desktop/) und Docker Compose

### Backend einrichten

1. **.env Datei erstellen**:
   Kopiere die `example.env` zu `.env` und passe die Werte an:

   ```bash
   cp example.env .env
   ```

2. **Backend mit Docker starten**:

   ```bash
   docker-compose up -d --build
   ```

   Dieser Befehl startet das Backend im Hintergrund. Das Backend ist dann unter http://localhost:8000 erreichbar.

3. **Swagger API-Dokumentation**:

   Die API-Dokumentation ist nach dem Start unter http://localhost:8000/docs verfügbar.

### Frontend (Flutter App) einrichten

1. **Flutter-Abhängigkeiten installieren**:

   ```bash
   flutter pub get
   ```

2. **App auf einem Emulator oder Gerät starten**:

   ```bash
   flutter run
   ```

   Wenn mehrere Geräte angeschlossen sind, wähle das gewünschte Gerät aus.

## 🔧 Entwicklung

### Projektstruktur

```
lib/
├── core/           # Kernkomponenten und Dienste
├── features/       # Feature-Module nach Funktionalität organisiert
├── models/         # Datenmodelle
├── router/         # App-Routinglogik
├── theme/          # Theme-Definitionen
└── main.dart       # Einstiegspunkt der App
```

### Backend-Entwicklung

Das Backend basiert auf FastAPI und MongoDB:

```
backend/
├── models.py       # Datenmodelle
├── main.py         # API-Endpunkte
├── llm_service.py  # KI-Dienste
└── requirements.txt # Abhängigkeiten
```

## 📝 Umgebungsvariablen

### `.env` (Private Konfiguration)

Diese Datei enthält sensible Daten und sollte nicht in der Versionskontrolle gespeichert werden:

- `MONGODB_URL`: MongoDB-Verbindungs-URL
- `DB_NAME`: Name der Datenbank
- `AZURE_OPENAI_*`: Azure OpenAI API-Einstellungen für KI-Funktionen

### `public.env` (Öffentliche Konfiguration)

Diese Datei enthält öffentliche Konfigurationen:

- `BACKEND_URL`: URL zum Backend-Server
- `PORT`: Port für den Backend-Server
- `CORS_ORIGINS`: Erlaubte Origins für CORS
