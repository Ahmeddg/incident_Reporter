require("dotenv").config();
const express = require("express");
const cors = require("cors");
const dialogflow = require("@google-cloud/dialogflow");
const { v4: uuidv4 } = require("uuid");

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const MODEL_API_URL = process.env.MODEL_API_URL || "http://localhost:11434/api/chat";
const MODEL_API_KEY = process.env.MODEL_API_KEY || "";
const MODEL_NAME = process.env.MODEL_NAME || "gemma3:27b-cloud";
const MODEL_TIMEOUT_MS = Number(process.env.MODEL_TIMEOUT_MS || 2500);

// Mémoire de session pour conserver les infos entre les messages
const sessions = {};
const CAMUNDA_CREATE_INSTANCE_URL = process.env.CAMUNDA_CREATE_INSTANCE_URL || "";
const CAMUNDA_BPMN_PROCESS_ID = process.env.CAMUNDA_BPMN_PROCESS_ID || "";
const CAMUNDA_PROCESS_VERSION = Number(process.env.CAMUNDA_PROCESS_VERSION || -1);
const CAMUNDA_BEARER_TOKEN = process.env.CAMUNDA_BEARER_TOKEN || "";
const CAMUNDA_OAUTH_TOKEN_URL = process.env.CAMUNDA_OAUTH_TOKEN_URL || "";
const CAMUNDA_OAUTH_CLIENT_ID = process.env.CAMUNDA_OAUTH_CLIENT_ID || "";
const CAMUNDA_OAUTH_CLIENT_SECRET = process.env.CAMUNDA_OAUTH_CLIENT_SECRET || "";
const CAMUNDA_OAUTH_AUDIENCE = process.env.CAMUNDA_OAUTH_AUDIENCE || "";
const CAMUNDA_TENANT_ID = process.env.CAMUNDA_TENANT_ID || "";
const EMERGENCY_KEYWORDS = [
  "cadavre",
  "corps",
  "corps sans vie",
  "morte",
  "mort",
  "deceased",
  "unconscious",
  "inconscient",
  "ne respire",
  "pas de respiration",
  "arrêt respiratoire",
  "arret respiratoire",
  "hémorragie",
  "hemorragie",
  "saignement",
  "saignement abondant",
  "perte de sang",
  "sang",
  "saigne",
  "saigne beaucoup",
  "coupé",
  "coupe",
  "blessé",
  "blesse",
  "étouffe",
  "etouffe",
  "brûle",
  "brule",
  "douleur thoracique",
  "crise cardiaque",
  "avc",
  "urgence",
  "accident",
  "fire",
  "feu",
  "violence"
];
const HELP_KEYWORDS = [
  "aide",
  "help",
  "au secours",
  "besoin d'aide",
  "besoin aide",
  "sos"
];
const EMERGENCY_DISPATCH_MESSAGE =
  process.env.EMERGENCY_DISPATCH_MESSAGE ||
  "Notre système transmet la demande en priorité au service d'urgence partenaire pour accélérer l'envoi d'une ambulance.";
const ASSISTANT_SYSTEM_PROMPT = `
Tu es un assistant d'urgence bienveillant, calme et professionnel.
Ton rôle : guider l'utilisateur pas à pas pendant une urgence, en attendant l'arrivée des secours.

RÈGLES STRICTES DE COMMUNICATION :
1. Ne jamais dire à l'utilisateur d'appeler le 112, le 15 ou la police. Les secours sont déjà prévenus par l'application.
2. Ne jamais répéter une information déjà confirmée (ex: ne pas redire "l'ambulance est en route" à chaque message, la dire une seule fois au début).
3. Ne pas mettre des phrases en majuscules. Utilise un ton calme et rassurant, comme un professionnel de santé.
4. Une seule question à la fois. Ne pose jamais plusieurs questions dans le même message.
5. Donne des gestes de premiers secours clairs et validés (RCP, PLS, compression de plaie).
6. Tes réponses doivent être courtes : max 4-5 lignes. Chaque seconde compte.

STYLE :
- Chaud, rassurant, court.
- Pas de répétition d'infos déjà dites.
- Si tu as déjà demandé la respiration et qu'on t'a répondu, PASSE à la question suivante (conscience, saignement).

QUAND LE DOSSIER EST COMPLET : 
Dis simplement, en 2-3 lignes maximum :
"Parfait. Les secours ont toutes les informations et l'ambulance est en chemin. 🚑
Restez joignable sur cette application — l'ambulancier pourra vous contacter directement pour vous guider jusqu'à l'arrivée."
`;

function normalizeText(text) {
  return (text || "").toLowerCase();
}

function isEmergencyText(userText) {
  const txt = normalizeText(userText);
  return EMERGENCY_KEYWORDS.some((w) => txt.includes(w));
}

function isHelpRequest(userText) {
  const txt = normalizeText(userText);
  return HELP_KEYWORDS.some((w) => txt.includes(w));
}

function extractFromDialogflow(reqBody) {
  const params = reqBody?.queryResult?.parameters || {};
  const address =
    params.address ||
    params["geo-city"] ||
    params["street-address"] ||
    params.location ||
    "";
  return {
    address: typeof address === "string" ? address.trim() : "",
    age: typeof params.age === "number" ? params.age : null
  };
}

function extractCriticalInfo(userText, reqBody) {
  const txt = normalizeText(userText);
  const df = extractFromDialogflow(reqBody);

  let patientState = "inconnu";
  if (
    txt.includes("cadavre") ||
    txt.includes("corps sans vie") ||
    txt.includes("deceased") ||
    txt.includes("mort")
  ) {
    patientState = "cadavre";
  }
  // On ne définit patientState sur 'humain' que si vraiment précis
  if (txt.includes("humain")) {
    patientState = "humain";
  }

  let breathing = "inconnu";
  if (
    txt.includes("ne respire pas") ||
    txt.includes("pas de respiration") ||
    txt.includes("arrêt respiratoire") ||
    txt.includes("arret respiratoire") ||
    txt.includes("not breathing")
  ) {
    breathing = "absente";
  } else if (
    txt.includes("respire") ||
    txt.includes("breathing") ||
    txt.includes("respiration normale")
  ) {
    breathing = "présente";
  }

  let consciousness = "inconnu";
  if (
    txt.includes("inconscient") ||
    txt.includes("unconscious") ||
    txt.includes("ne répond pas") ||
    txt.includes("ne repond pas")
  ) {
    consciousness = "inconscient";
  } else if (
    txt.includes("conscient") ||
    txt.includes("répond") ||
    txt.includes("repond") ||
    txt.includes("awake")
  ) {
    consciousness = "conscient";
  }

  let bloodLoss = "inconnue";
  if (
    txt.includes("hémorragie") ||
    txt.includes("hemorragie") ||
    txt.includes("saignement abondant") ||
    txt.includes("perte de sang importante") ||
    txt.includes("bleeding heavily")
  ) {
    bloodLoss = "importante";
  } else if (txt.includes("sang") || txt.includes("saignement")) {
    bloodLoss = "présente";
  } else if (
    txt.includes("pas de sang") || 
    txt.includes("no blood") || 
    txt.includes("ne saigne pas") ||
    txt === "non" ||
    txt.includes("non pas de")
  ) {
    bloodLoss = "absente";
  }

  const victimCountMatch = txt.match(/(\d+)\s*(personnes|victimes|people)/i);
  const victimCount = victimCountMatch ? Number(victimCountMatch[1]) : 1;
  const ageMatch = txt.match(/(\d{1,3})\s*ans/i);
  const approxAge = df.age || (ageMatch ? Number(ageMatch[1]) : null);
  // Sécurité renforcée pour éviter les fausses adresses
  let location = "";
  const exclusionWords = ["aussi", "aujourd'hui", "secours", "urgent", "urgence", "vite"];
  const containsExclusion = exclusionWords.some(word => txt.includes(word));

  if (!containsExclusion) {
    const locationMatch = userText.match(/\b(?:adresse|à|au|sur)\b\s*[:\-]?\s*([^,.!\n]+)/i);
    location = df.address || (locationMatch ? locationMatch[1].trim() : "");
  } else {
    location = df.address || "";
  }

  let severity = "inconnu";
  if (
    patientState === "cadavre" ||
    breathing === "absente" ||
    bloodLoss === "importante" ||
    consciousness === "inconscient" ||
    txt.includes("crise cardiaque") ||
    txt.includes("douleur thoracique") ||
    txt.includes("avc")
  ) {
    severity = "critique";
  } else if (txt.includes("accident") || txt.includes("violence") || txt.includes("feu")) {
    severity = "élevée";
  }

  return {
    patientState,
    severity: severity === "inconnu" ? "modérée" : severity, // Fallback safe
    bloodLoss,
    breathing,
    consciousness,
    victimCount,
    approxAge,
    location,
    description: (userText || "").trim()
  };
}

function missingCriticalFields(info) {
  const missing = [];
  if (!info.location) missing.push("adresse exacte");
  if (info.breathing === "inconnu") missing.push("respiration");
  if (info.consciousness === "inconnu") missing.push("conscience");
  if (info.bloodLoss === "inconnue") missing.push("perte de sang");
  if (info.patientState === "inconnu") missing.push("état (humain/cadavre)");
  return missing;
}

function hasCompleteCriticalInfo(info) {
  return missingCriticalFields(info).length === 0;
}

function buildFirstAidSteps(info) {
  const steps = [];
  if (info.patientState === "cadavre") {
    steps.push("Ne déplacez pas le corps sauf danger immédiat et sécurisez la zone.");
    return steps;
  }
  if (info.breathing === "absente") {
    steps.push("Commencez la RCP immédiatement si vous êtes formé.");
  }
  if (info.bloodLoss === "importante" || info.bloodLoss === "présente") {
    steps.push("Appliquez une compression directe continue sur la plaie avec un tissu propre.");
  }
  if (info.consciousness === "inconscient" && info.breathing === "présente") {
    steps.push("Mettez la personne en position latérale de sécurité.");
  }
  if (steps.length === 0) {
    steps.push("Gardez la personne immobile, au chaud, et surveillez respiration et conscience.");
  }
  return steps;
}

function getEmergencyFallback(userText) {
  const isEmergency = isEmergencyText(userText);
  if (!isEmergency) {
    // Si ce n'est pas une urgence, on donne une réponse de secours polyvalente
    return "Je suis votre assistant de sécurité. Je peux vous guider pour des premiers secours ou des urgences. Que se passe-t-il précisément ?";
  }

  const info = extractCriticalInfo(userText, {});
  return [
    "Urgence: appelez immédiatement les secours locaux (112 / 15 / 911 selon votre pays).",
    "Je collecte les informations vitales pour déclencher l'intervention.",
    `Résumé initial: état=${info.patientState}, gravité=${info.severity}, saignement=${info.bloodLoss}, respiration=${info.breathing}, conscience=${info.consciousness}.`,
    "Donnez maintenant: adresse exacte, respiration, conscience, perte de sang."
  ].join("\n");
}

function getHelpTriageFallback() {
  return [
    "Je suis là pour vous aider.",
    "Si c'est une urgence vitale, appelez immédiatement les secours locaux (112 / 15 / 911 selon votre pays).",
    `Coordination: ${EMERGENCY_DISPATCH_MESSAGE}`,
    "Donnez-moi ces détails maintenant: 1) adresse exacte, 2) état (humain/cadavre), 3) respiration, 4) conscience, 5) perte de sang.",
    "Je peux ensuite vous guider pas à pas avec les premiers secours adaptés."
  ].join("\n");
}

async function getCamundaBearerToken() {
  if (CAMUNDA_BEARER_TOKEN) {
    return CAMUNDA_BEARER_TOKEN;
  }
  if (
    !CAMUNDA_OAUTH_TOKEN_URL ||
    !CAMUNDA_OAUTH_CLIENT_ID ||
    !CAMUNDA_OAUTH_CLIENT_SECRET ||
    !CAMUNDA_OAUTH_AUDIENCE
  ) {
    return "";
  }

  const tokenResponse = await fetch(CAMUNDA_OAUTH_TOKEN_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded"
    },
    body: new URLSearchParams({
      grant_type: "client_credentials",
      client_id: CAMUNDA_OAUTH_CLIENT_ID,
      client_secret: CAMUNDA_OAUTH_CLIENT_SECRET,
      audience: CAMUNDA_OAUTH_AUDIENCE
    })
  });

  if (!tokenResponse.ok) {
    const errorText = await tokenResponse.text();
    throw new Error(`Camunda token error ${tokenResponse.status}: ${errorText}`);
  }

  const tokenData = await tokenResponse.json();
  return tokenData.access_token || "";
}

async function startCamundaEmergencyInstance(criticalInfo) {
  if (!CAMUNDA_CREATE_INSTANCE_URL || !CAMUNDA_BPMN_PROCESS_ID) {
    return {
      started: false,
      reason: "camunda_not_configured"
    };
  }

  const token = await getCamundaBearerToken();
  if (!token) {
    return {
      started: false,
      reason: "camunda_missing_token"
    };
  }

  const body = {
    processDefinitionId: CAMUNDA_BPMN_PROCESS_ID,
    variables: criticalInfo
  };
  if (CAMUNDA_PROCESS_VERSION > 0) {
    body.processDefinitionVersion = CAMUNDA_PROCESS_VERSION;
  }
  if (CAMUNDA_TENANT_ID) {
    body.tenantId = CAMUNDA_TENANT_ID;
  }

  const headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`
  };

  const response = await fetch(CAMUNDA_CREATE_INSTANCE_URL, {
    method: "POST",
    headers,
    body: JSON.stringify(body)
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Camunda start error ${response.status}: ${errorText}`);
  }

  const data = await response.json();
  return {
    started: true,
    instanceKey: data.processInstanceKey || data.processInstanceId || null
  };
}

function buildMissingInfoPrompt(info, isFirstMessage = false) {
  const missing = missingCriticalFields(info);
  const firstMissing = missing[0];

  const questions = {
    "adresse exacte": "Où vous trouvez-vous exactement ? Une adresse ou un point de repère suffit.",
    "respiration": "Est-ce que la personne respire ?",
    "conscience": "La personne est-elle consciente ? Répond-elle si vous lui parlez ?",
    "perte de sang": "Y a-t-il un saignement visible ?"
  };

  const question = questions[firstMissing] || `Pouvez-vous me préciser : ${missing[0]} ?`;

  const firstAid = buildFirstAidSteps(info);
  const lines = [];

  // Le message de confirmation n'est affiché qu'au tout premier message
  if (isFirstMessage) {
    lines.push("Signalement bien reçu. Nos équipes sont alertées. 🚑");
    lines.push("");
  }

  // Gestes immédiats si on en a
  if (firstAid.length > 0) {
    lines.push("En attendant les secours :");
    firstAid.forEach(step => lines.push(`• ${step}`));
    lines.push("");
  }

  // La seule question vitale manquante
  lines.push(question);

  return lines.join("\n");
}

function buildEmergencyResponse(info) {
  const steps = buildFirstAidSteps(info);
  const lines = [
    "Parfait. Les secours ont toutes les informations. L'ambulance est en chemin. 🚑",
    "",
    "📱 Restez joignable sur cette application — l'ambulancier pourra vous contacter directement pour vous guider jusqu'à son arrivée."
  ];

  if (steps.length > 0) {
    lines.push("");
    lines.push("En attendant leur arrivée :");
    steps.forEach(s => lines.push(`• ${s}`));
  }

  lines.push("");
  lines.push("Restez calme et restez avec la victime.");

  return lines.join("\n");
}

async function callModelAPI(userText, triageContext = "", history = []) {
  const hasTimeout = MODEL_TIMEOUT_MS && MODEL_TIMEOUT_MS > 0;
  const controller = hasTimeout ? new AbortController() : null;
  const timeout = hasTimeout ? setTimeout(() => controller.abort(), MODEL_TIMEOUT_MS) : null;
  let response;
  try {
    const headers = { "Content-Type": "application/json" };
    if (MODEL_API_KEY) headers.Authorization = `Bearer ${MODEL_API_KEY}`;

    const isGenerateEndpoint = MODEL_API_URL.includes("/api/generate");

    // Construction du prompt avec le contexte de triage injecté dans le système
    const fullSystemPrompt = `${ASSISTANT_SYSTEM_PROMPT}\n${triageContext}`;

    let body;
    if (isGenerateEndpoint) {
      // Pour Ollama /generate : on concatène tout
      let fullPrompt = `System: ${fullSystemPrompt}\n\n`;
      history.forEach(msg => {
        fullPrompt += `${msg.role === "user" ? "User" : "Assistant"}: ${msg.content}\n`;
      });
      if (history.length === 0 || history[history.length-1].content !== userText) {
          fullPrompt += `User: ${userText}\nAssistant:`;
      } else {
          fullPrompt += `Assistant:`;
      }
      
      body = {
        model: MODEL_NAME,
        prompt: fullPrompt,
        stream: false,
        options: { temperature: 0.4 }
      };
    } else {
      // Pour OpenAI / Groq / Ollama /chat : on utilise le format messages
      const messages = [
        { role: "system", content: fullSystemPrompt },
        ...history
      ];
      // Si le dernier message de l'history n'est pas celui qu'on vient d'ajouter
      if (history.length === 0 || history[history.length-1].content !== userText) {
          messages.push({ role: "user", content: userText });
      }

      body = {
        model: MODEL_NAME,
        messages: messages,
        stream: false,
        options: { temperature: 0.4 }
      };
    }

    response = await fetch(MODEL_API_URL, {
      method: "POST",
      headers,
      body: JSON.stringify(body),
      signal: controller ? controller.signal : undefined
    });
  } catch (error) {
    if (error.name === "AbortError") {
      const timeoutError = new Error(`Model API timeout after ${MODEL_TIMEOUT_MS}ms`);
      timeoutError.status = 408;
      throw timeoutError;
    }
    throw error;
  } finally {
    if (timeout) clearTimeout(timeout);
  }

  if (!response.ok) {
    const errorText = await response.text();
    const error = new Error(`Model API error ${response.status}: ${errorText}`);
    error.status = response.status;
    throw error;
  }

  const data = await response.json();
  const text =
    data?.message?.content?.trim() ||
    data?.response?.trim() ||
    data?.choices?.[0]?.message?.content?.trim() ||
    "";
  
  if (!text && isEmergencyText(userText)) {
      return getEmergencyFallback(userText);
  }

  return text || "Je suis là pour vous aider. Précisez votre situation.";
}

app.post("/webhook", async (req, res) => {
  const userText = req.body?.queryResult?.queryText || req.body?.text || "";
  
  // Extraction fiable du Session ID depuis le chemin Dialogflow ou le body
  let sessionId = "default";
  if (req.body.session) {
    const parts = req.body.session.split("/");
    sessionId = parts[parts.length - 1];
  } else if (req.body.sessionId) {
    sessionId = req.body.sessionId;
  }

  console.log(`[Webhook] Session: ${sessionId} | Text: ${userText}`);

  if (!userText) {
    return res.json({ fulfillmentText: "I did not receive any message." });
  }

  // Récupérer ou créer l'état de la session
  let sessionState = sessions[sessionId] || { criticalInfo: null, isEmergency: false };

  const urgentDetected = isEmergencyText(userText);
  
  if (urgentDetected || sessionState.isEmergency) {
    sessionState.isEmergency = true;
    
    // Extraire et fusionner les infos vitales (Sécurité)
    const newInfo = extractCriticalInfo(userText, req.body);
    if (!sessionState.criticalInfo) {
      sessionState.criticalInfo = newInfo;
    } else {
      Object.keys(newInfo).forEach(key => {
        if (newInfo[key] && newInfo[key] !== "inconnu" && newInfo[key] !== "inconnue") {
          sessionState.criticalInfo[key] = newInfo[key];
        }
      });
    }

    // Gestion OUI/NON
    const simpleText = userText.toLowerCase().trim();
    if (simpleText === "oui" || simpleText === "non") {
      const missing = missingCriticalFields(sessionState.criticalInfo);
      const targetField = missing[0]; 
      if (targetField === "respiration") sessionState.criticalInfo.breathing = (simpleText === "oui" ? "présente" : "absente");
      else if (targetField === "conscience") sessionState.criticalInfo.consciousness = (simpleText === "oui" ? "conscient" : "inconscient");
      else if (targetField === "perte de sang") sessionState.criticalInfo.bloodLoss = (simpleText === "oui" ? "présente" : "absente");
    }

    if (!sessionState.history) sessionState.history = [];
    
    sessions[sessionId] = sessionState;

    const isComplete = hasCompleteCriticalInfo(sessionState.criticalInfo);

    // APPEL À L'IA AVEC MÉMOIRE (HISTORY)
    try {
      const triageContext = `
[CONTEXTE MÉDICAL ACTUEL]
- Complet : ${isComplete ? "OUI" : "NON"}
- Données confirmées : ${JSON.stringify(sessionState.criticalInfo)}
- Champs à obtenir : ${missingCriticalFields(sessionState.criticalInfo).join(", ")}
INTERDICTION : Ne pose pas de question sur un champ déjà connu (confirmé).
      `;

      // On ajoute le message actuel à l'historique
      sessionState.history.push({ role: "user", content: userText });
      
      // On limite l'historique aux 10 derniers échanges
      if (sessionState.history.length > 10) sessionState.history.shift();

      const aiResponse = await callModelAPI(userText, triageContext, sessionState.history);
      
      // On ajoute la réponse de l'IA à l'historique
      sessionState.history.push({ role: "assistant", content: aiResponse });
      
      // Si le dossier est complet, on démarre Camunda en arrière-plan
      if (isComplete) {
        startCamundaEmergencyInstance(sessionState.criticalInfo).catch(console.error);
      }

      return res.json({
        fulfillmentText: aiResponse,
        payload: { criticalInfo: sessionState.criticalInfo, isComplete }
      });

    } catch (error) {
      console.log("IA Error during emergency, switching to local safety mode.");
      // FALLBACK DE SÉCURITÉ SI L'IA BLOQUE
      if (isComplete) {
        return res.json({ fulfillmentText: buildEmergencyResponse(sessionState.criticalInfo, true) });
      } else {
        return res.json({ fulfillmentText: buildMissingInfoPrompt(sessionState.criticalInfo) });
      }
    }
  }

  if (isHelpRequest(userText)) {
    return res.json({ fulfillmentText: getHelpTriageFallback() });
  }

  try {
    const reply = await callModelAPI(userText);
    return res.json({ fulfillmentText: reply });
  } catch (error) {
    const emergencyFallback = getEmergencyFallback(userText);
    const helpFallback = isHelpRequest(userText) ? getHelpTriageFallback() : null;
    return res.json({
      fulfillmentText: helpFallback || emergencyFallback,
      payload: {
        error: error.message
      }
    });
  }
});

app.get("/health", async (req, res) => {
  res.json({
    ok: true,
    modelApiUrl: MODEL_API_URL,
    model: MODEL_NAME,
    camundaConfigured: Boolean(CAMUNDA_CREATE_INSTANCE_URL && CAMUNDA_BPMN_PROCESS_ID)
  });
});

app.post("/api/chat", async (req, res) => {
  const text = req.body.text;
  const sessionId = req.body.sessionId || uuidv4();
  const initialContext = req.body.initialContext;
  
  console.log(`[API] Session: ${sessionId} | InitialContext: ${initialContext ? "OUI" : "NON"}`);

  if (!text && !initialContext) {
    return res.status(400).json({ error: "Text or initialContext is required" });
  }

  // Initialisation ou Réinitialisation de la mémoire
  if (initialContext || !sessions[sessionId]) {
    console.log(`[API] Reset/Init Session: ${sessionId}`);
    sessions[sessionId] = { 
      criticalInfo: {
        patientState: "inconnu",
        severity: "inconnu",
        bloodLoss: "inconnu",
        breathing: "inconnu",
        consciousness: "inconnu",
        location: "inconnu",
        description: "inconnu"
      }, 
      history: [],
      isEmergency: !!initialContext 
    };
  }

  if (initialContext) {
    let sessionState = sessions[sessionId];
    sessionState.isEmergency = true;
    
    // On mappe le formulaire
    if (initialContext.location) sessionState.criticalInfo.location = initialContext.location;
    if (initialContext.emergencyType) sessionState.criticalInfo.patientState = initialContext.emergencyType;
    if (initialContext.description) sessionState.criticalInfo.description = initialContext.description;
    if (initialContext.severity) sessionState.criticalInfo.severity = initialContext.severity;

    // Construire le message d'accueil professionnel avec les infos du formulaire
    const info = sessionState.criticalInfo;

    const welcomeLines = [
      "Signalement reçu. Nos équipes sont alertées.",
      "──────────────────────────",
    ];

    if (info.patientState && info.patientState !== "inconnu") {
      welcomeLines.push(`Incident       : ${info.patientState}`);
    }
    if (info.severity && info.severity !== "inconnu") {
      welcomeLines.push(`Gravité        : ${info.severity}`);
    }
    if (info.location && info.location !== "inconnu") {
      welcomeLines.push(`Localisation   : ${info.location}`);
    }
    if (info.description && info.description !== "inconnu" && info.description.trim() !== "") {
      welcomeLines.push(`Description    : ${info.description}`);
    }

    welcomeLines.push("──────────────────────────");
    welcomeLines.push("Restez connecté à cette application. Les secours peuvent vous contacter ici.");
    welcomeLines.push("");

    const missing = missingCriticalFields(info);
    const questions = {
      "adresse exacte": "Pouvez-vous préciser l'adresse exacte ou un point de repère visible ?",
      "respiration": "La victime respire-t-elle normalement ?",
      "conscience": "La victime est-elle consciente ? Répond-elle si vous lui parlez ?",
      "perte de sang": "Y a-t-il un saignement visible ?"
    };

    if (missing.length > 0) {
      welcomeLines.push(questions[missing[0]] || `Précisez : ${missing[0]}`);
    }

    return res.json({
      text: welcomeLines.join("\n"),
      sessionId: sessionId
    });
  }

  try {
    const sessionClient = new dialogflow.SessionsClient({
      keyFilename: "./google-credentials.json"
    });
    const sessionPath = sessionClient.projectAgentSessionPath(
      "my-chatbot-g9ab",
      sessionId
    );

    const request = {
      session: sessionPath,
      queryInput: {
        text: {
          text: text,
          languageCode: "fr"
        }
      }
    };

    const responses = await sessionClient.detectIntent(request);
    const result = responses[0].queryResult;

    // Log for debugging
    console.log(`Query: ${text}`);
    console.log(`Response: ${result.fulfillmentText}`);

    res.json({
      text: result.fulfillmentText,
      intent: result.intent?.displayName,
      parameters: result.parameters?.fields,
      sessionId: sessionId
    });
  } catch (error) {
    console.error("Dialogflow Error:", error);
    res.status(500).json({ error: "Failed to communicate with Dialogflow" });
  }
});

app.listen(PORT, () => {
  console.log(`Webhook server running on http://localhost:${PORT}`);
  console.log(`Using model API: ${MODEL_API_URL}`);
  console.log(`Using model: ${MODEL_NAME}`);
});
