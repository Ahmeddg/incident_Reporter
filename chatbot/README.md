# Dialogflow + Emergency Chatbot

This project is a Dialogflow webhook connected to a local model API endpoint.

## 1) Install

```bash
npm install
```

## 2) Configure

```bash
copy .env.example .env
```

Set these values in `.env`:
- `MODEL_API_URL` (default `http://localhost:11434/api/chat`)
- `MODEL_API_KEY`
- `MODEL_NAME` (default `gemma3:27b-cloud`)
- `CAMUNDA_CREATE_INSTANCE_URL` (Zeebe REST endpoint to create process instance)
- `CAMUNDA_BPMN_PROCESS_ID`
- `CAMUNDA_PROCESS_VERSION` (`-1` for latest, or explicit version)
- Auth (one option):
  - Static bearer: `CAMUNDA_BEARER_TOKEN`
  - OAuth client credentials: `CAMUNDA_OAUTH_TOKEN_URL`, `CAMUNDA_OAUTH_CLIENT_ID`, `CAMUNDA_OAUTH_CLIENT_SECRET`, `CAMUNDA_OAUTH_AUDIENCE`
- Optional: `CAMUNDA_TENANT_ID`

## 3) Run

```bash
npm start
```

Webhook URL (local):
- `http://localhost:3000/webhook`
- Health check: `http://localhost:3000/health`

## 4) Expose for Dialogflow

```bash
ngrok http 3000
```

Use `https://YOUR_NGROK_URL/webhook` in Dialogflow Fulfillment.

## 5) Dialogflow setup

1. Create/open your agent in Dialogflow ES.
2. Fulfillment -> enable Webhook and set webhook URL.
3. In each intent to use AI, enable "Enable webhook call for this intent".
4. Remove static text responses if you want webhook-only behavior.

## Notes

- Emergency messages are triaged into critical fields: patient state (humain/cadavre), severity, blood loss, breathing, consciousness, victims, location.
- If critical fields are complete, the webhook starts a Camunda SaaS process instance and returns concise first-aid guidance while confirming ambulance dispatch.
- If fields are missing, the bot asks only for missing critical data.
- Generic "help" messages also return a structured triage fallback.
