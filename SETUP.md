# Incident Reporter — Setup Guide

A Flutter-based emergency incident reporting app with an AI-powered chatbot backend.

---

## Prerequisites

Make sure you have these installed before you start:

| Tool | Version | Download |
|------|---------|----------|
| Flutter SDK | >= 3.0 | https://flutter.dev/docs/get-started/install |
| Node.js | >= 18 | https://nodejs.org |
| ngrok | Any | https://ngrok.com/download |
| Dialogflow (Google Cloud) Account | — | https://dialogflow.cloud.google.com |
| Ollama Cloud Account | — | https://ollama.com |

---

## 1. Clone the Repository

```bash
git clone https://github.com/Ahmeddg/incident_Reporter.git
cd incident_Reporter
```

---

## 2. Setup the Chatbot Backend (Node.js)

### a. Install dependencies
```bash
cd chatbot
npm install
```

### b. Create your environment file
```bash
# Copy the example file
copy .env.example .env   # Windows
cp .env.example .env     # Mac/Linux
```

Then open `.env` and fill in your values:
- `MODEL_API_KEY` → Your Ollama Cloud API key (get one at https://ollama.com)
- Leave the Camunda fields empty if you don't use workflow automation.

### c. Add your Google Dialogflow credentials
- Go to Google Cloud Console → IAM → Service Accounts.
- Download your service account JSON key.
- Rename it to `google-credentials.json` and put it in the `chatbot/` folder.

### d. Start the chatbot server
```bash
npm start
# Server will run on http://localhost:3000
```

---

## 3. Expose the Server to the Internet (ngrok)

The Flutter app (and Dialogflow) needs a public URL to talk to your local server.

```bash
# In a separate terminal:
ngrok http 3000
```

Copy the HTTPS URL that ngrok gives you (example: `https://abc123.ngrok.io`).

---

## 4. Configure the Flutter App

Open the file `lib/core/config/app_config.dart` and update the chatbot URL:

```dart
static const String chatbotBaseUrl = 'https://abc123.ngrok.io'; // Your ngrok URL
```

---

## 5. Setup Dialogflow Webhook

1. Go to your Dialogflow agent settings.
2. Navigate to **Fulfillment**.
3. Enable **Webhook**.
4. Set the URL to: `https://abc123.ngrok.io/webhook`
5. Save.

---

## 6. Run the Flutter App

```bash
# Go back to the root of the project
cd ..

# Get Flutter dependencies
flutter pub get

# Run on Chrome (Web)
flutter run -d chrome

# Or run on a connected Android/iOS device
flutter run
```

---

## Project Structure

```
incident_Reporter/
├── lib/                          # Flutter app source code
│   ├── core/
│   │   ├── config/app_config.dart    # API URLs configuration
│   │   └── services/
│   │       ├── chatbot_service.dart  # Communicates with Node.js backend
│   │       └── mock_emergency_service.dart  # Chat logic & state
│   └── ui/screens/               # App screens and UI
├── chatbot/                      # Node.js backend
│   ├── server.js                 # Main server: AI triage + Dialogflow webhook
│   ├── .env.example              # Environment variables template
│   ├── package.json              # Node.js dependencies
│   └── README.md                 # Chatbot-specific docs
└── SETUP.md                      # This file
```

---

## How it Works

```
User fills form (Flutter)
        ↓
ChatbotService sends context to Node.js backend (/api/chat)
        ↓
Node.js extracts critical info (location, type, severity)
        ↓
AI Model (Gemma via Ollama) generates a natural, guided response
        ↓
If AI is unavailable: local safety fallback kicks in
        ↓
When all info is collected: Camunda workflow triggered (optional)
        ↓
User sees: "Ambulance is on the way. Stay reachable on this app."
```

---

## Common Issues

| Problem | Solution |
|---------|----------|
| `Error: google-credentials.json not found` | Add your Dialogflow service account key to `chatbot/` |
| `AI is not responding` | Check your `MODEL_API_KEY` in `.env`. Make sure the model is available on your Ollama account. |
| `App can't reach the server` | Make sure ngrok is running and the URL in `app_config.dart` is up to date. |
| `Camunda 503 error in logs` | Normal if you haven't configured Camunda. It's optional and won't affect the chatbot. |

---

## Notes

- **Never commit your `.env` or `google-credentials.json`** — they are blocked by `.gitignore`.
- The `ngrok` URL changes every time you restart it. Update `app_config.dart` accordingly.
- For production, replace ngrok with a real server (e.g., Railway, Render, or a VPS).
