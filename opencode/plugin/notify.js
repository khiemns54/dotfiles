import { execFile } from "child_process";

const VOICE = "Ava";
const SPEAK_COOLDOWN_MS = 30000;
const ENABLE_SPEECH = process.env.OPENCODE_NOTIFY_SPEECH === "1";
const STATUS_KEY = "opencode_session";
const ICON_ONLY_STATUS_VALUE = "\u00A0";
const WINDOW_NAME_MAX = 120;
const ATTENTION_PREFIX = "[!] ";
const TITLE_MAX_LENGTH = 60;
const TITLE_MIN_WORDS = 2;
const GENERIC_TITLE_PATTERNS = [/^session\b/i, /^new session\b/i, /^untitled\b/i, /^workspace session\b/i];

const renameInFlight = new Set();
const autoNamedSessions = new Set();
const lastSpokenByEvent = new Map();
const sessionMetaCache = new Map();
let baseWindowName = null;
let isWindowMarked = false;

const execFileAsync = (command, args) => {
  return new Promise((resolve, reject) => {
    execFile(command, args, (error, stdout) => {
      if (error) {
        reject(error);
        return;
      }

      resolve((stdout || "").trim());
    });
  });
};

const formatPermissionRequest = (permission) => {
  if (!permission) {
    return "A permission request needs your approval.";
  }

  if (permission.title) {
    return `Permission required: ${permission.title}.`;
  }

  if (permission.type) {
    return `Permission required for ${permission.type}.`;
  }

  return "A permission request needs your approval.";
};

const getSessionLabel = (properties) => {
  const info = properties?.info;
  const id = properties?.sessionID || info?.id;
  const title = info?.title;

  if (id && title) {
    return title;
  }

  if (title) {
    return title;
  }

  if (id) {
    return "This session";
  }

  return "Session";
};


const ALLOWED_EVENTS = new Set([
  "permission.asked",
  "permission.replied",
  "question.asked",
  "question.replied",
  "question.rejected",
  "session.error",
  "session.idle",
  "message.updated",
]);

const ACTION_REQUIRED_EVENTS = new Set(["permission.asked", "question.asked", "question.rejected", "session.error"]);
const ACTION_RESOLVED_EVENTS = new Set(["permission.replied", "question.replied", "session.idle"]);



const EVENT_MESSAGES = {
  "permission.asked": (event) => formatPermissionRequest(event.properties),
  "question.asked": () => "A question is waiting for your input.",
  "question.rejected": () => "A question timed out and needs your attention.",
  "session.idle": () => "Task done.",
  "session.error": (event) => {
    const sessionLabel = getSessionLabel(event.properties);
    const detail = event.properties?.error?.data?.message || event.properties?.error?.name;
    return detail ? `${sessionLabel} ran into an issue: ${detail}.` : `${sessionLabel} ran into an issue.`;
  },
  "message.updated": () => null,
};

const STATUS_ICON_BY_EVENT = {
  "message.updated": "loader",
  "permission.asked": "shield-alert",
  "question.asked": "message-circle-question",
  "session.error": "triangle-alert",
};

const CMUX_NOTIFY_EVENTS = new Set(["permission.asked", "session.idle"]);

const speak = (message) => {
  if (!message) {
    return;
  }

  execFile("say", ["--voice", VOICE, message]);
};

const isTmuxSession = () => {
  return Boolean(process.env.TMUX_PANE || process.env.TMUX);
};

const isCmuxSession = () => {
  return Boolean(process.env.CMUX_WORKSPACE_ID || process.env.CMUX_SURFACE_ID);
};

const runCmux = async (args) => {
  if (!isCmuxSession()) {
    return;
  }

  try {
    await execFileAsync("cmux", args);
  } catch {
    return;
  }
};

const clearCmuxStatus = async () => {
  await runCmux(["clear-status", STATUS_KEY]);
};

const setCmuxStatusIconOnly = async (icon) => {
  if (!icon) {
    return;
  }

  await clearCmuxStatus();
  await runCmux(["set-status", STATUS_KEY, ICON_ONLY_STATUS_VALUE, "--icon", icon]);
};

const sendCmuxNotification = async (event, message) => {
  if (!CMUX_NOTIFY_EVENTS.has(event.type) || !message) {
    return;
  }

  await clearCmuxStatus();
  await runCmux([
    "notify",
    "--title",
    "OpenCode",
    "--subtitle",
    getSessionLabel(event.properties),
    "--body",
    message,
  ]);
};

const normalizeWindowName = (name) => {
  const normalized = (name || "OpenCode")
    .replace(/\s+/g, " ")
    .replace(/[^\x20-\x7E]/g, "")
    .trim();

  if (normalized.length <= WINDOW_NAME_MAX) {
    return normalized;
  }

  return `${normalized.slice(0, WINDOW_NAME_MAX - 3).trim()}...`;
};

const normalizePathLabel = (rawPath) => {
  if (!rawPath) {
    return "~";
  }

  const home = process.env.HOME || "";
  if (home && rawPath.startsWith(home)) {
    const suffix = rawPath.slice(home.length);
    return suffix ? `~${suffix}` : "~";
  }

  return rawPath;
};

const getCurrentWindowName = async () => {
  if (!isTmuxSession()) {
    return null;
  }

  try {
    const target = process.env.TMUX_PANE ? ["display-message", "-p", "-t", process.env.TMUX_PANE, "#{window_name}"] : ["display-message", "-p", "#{window_name}"];
    const value = await execFileAsync("tmux", target);
    return value || null;
  } catch {
    return null;
  }
};

const getCurrentPanePath = async () => {
  if (!isTmuxSession()) {
    return null;
  }

  try {
    const target = process.env.TMUX_PANE
      ? ["display-message", "-p", "-t", process.env.TMUX_PANE, "#{pane_current_path}"]
      : ["display-message", "-p", "#{pane_current_path}"];
    const value = await execFileAsync("tmux", target);
    return value || null;
  } catch {
    return null;
  }
};

const renameCurrentWindow = async (name) => {
  if (!isTmuxSession()) {
    return;
  }

  try {
    const args = process.env.TMUX_PANE
      ? ["rename-window", "-t", process.env.TMUX_PANE, normalizeWindowName(name)]
      : ["rename-window", normalizeWindowName(name)];
    await execFileAsync("tmux", args);
  } catch {
    return;
  }
};

const setWindowAttentionOption = async (enabled, label = "") => {
  if (!isTmuxSession()) {
    return;
  }

  const target = process.env.TMUX_PANE;
  if (!target) {
    return;
  }

  try {
    await execFileAsync("tmux", ["set-option", "-w", "-t", target, "@opencode_attention", enabled ? "1" : "0"]);
    await execFileAsync("tmux", ["set-option", "-w", "-t", target, "@opencode_attention_label", normalizeWindowName(label || "")]);
  } catch {
    return;
  }
};

const buildAttentionWindowName = ({ baseName, eventType, panePath }) => {
  const base = normalizeWindowName(baseName || "OpenCode");
  const pathLabel = normalizePathLabel(panePath);
  const eventLabel = eventType || "attention";
  return `${ATTENTION_PREFIX}${base} - ${pathLabel} - opencode:${eventLabel}`;
};

const markActionWindow = async (label, eventType) => {
  if (!isTmuxSession()) {
    return;
  }

  if (!baseWindowName) {
    baseWindowName = await getCurrentWindowName();
  }

  const base = baseWindowName || "OpenCode";
  const panePath = await getCurrentPanePath();
  const decorated = buildAttentionWindowName({
    baseName: base,
    eventType,
    panePath,
  });
  await renameCurrentWindow(decorated);
  await setWindowAttentionOption(true, label || base);
  isWindowMarked = true;
};

const clearActionWindow = async () => {
  if (!isTmuxSession() || !isWindowMarked) {
    return;
  }

  const restore = baseWindowName || "OpenCode";
  await renameCurrentWindow(restore);
  await setWindowAttentionOption(false, "");
  isWindowMarked = false;
};

const handleTmuxAttention = async (event) => {
  if (ACTION_REQUIRED_EVENTS.has(event.type)) {
    await markActionWindow(getSessionLabel(event.properties), event.type);
    return;
  }

  if (ACTION_RESOLVED_EVENTS.has(event.type)) {
    await clearActionWindow();
  }
};

const shouldSpeakEvent = (eventType, message) => {
  if (!message) {
    return false;
  }

  const key = `${eventType}:${message}`;
  const now = Date.now();
  const lastSpokenAt = lastSpokenByEvent.get(key);
  if (lastSpokenAt && now - lastSpokenAt < SPEAK_COOLDOWN_MS) {
    return false;
  }

  lastSpokenByEvent.set(key, now);
  return true;
};

const resolveMessage = (event) => {
  if (!ALLOWED_EVENTS.has(event.type)) {
    return null;
  }

  const handler = EVENT_MESSAGES[event.type];
  if (!handler) {
    return null;
  }

  if (typeof handler === "function") {
    return handler(event);
  }

  return handler;
};

const cleanSnippet = (text = "") => {
  return text
    .replace(/```[\s\S]*?```/g, " ")
    .replace(/`[^`]+`/g, " ")
    .replace(/\s+/g, " ")
    .trim();
};

const isGenericTitle = (title = "") => {
  const normalized = title.trim();
  if (!normalized) {
    return true;
  }

  return GENERIC_TITLE_PATTERNS.some((pattern) => pattern.test(normalized));
};

const shouldUpdateTitle = (currentTitle, candidate) => {
  if (!candidate || candidate.length === 0) {
    return false;
  }

  if (currentTitle && !isGenericTitle(currentTitle)) {
    return false;
  }

  return currentTitle?.trim() !== candidate;
};

const extractUserPrompt = (message) => {
  if (!message) {
    return null;
  }

  if (message.summary?.title) {
    return message.summary.title;
  }

  const textPart = (message.parts || []).find((part) => part.type === "text" && part.text?.trim());
  if (!textPart) {
    return null;
  }

  return textPart.text;
};

const extractSessionID = (event) => {
  return event.properties?.sessionID || event.properties?.info?.id || event.properties?.info?.sessionID || null;
};

const looksBackgroundTitle = (title = "") => {
  return /\b(subtask|background|task run|agent task)\b/i.test(title);
};

const getSessionMeta = async (sessionID, client) => {
  if (!sessionID || !client) {
    return { isBackground: false };
  }

  if (sessionMetaCache.has(sessionID)) {
    return sessionMetaCache.get(sessionID);
  }

  try {
    const response = await client.session.get({ path: { id: sessionID } });
    const info = response?.data;
    const meta = {
      isBackground: Boolean(info?.parentID) || looksBackgroundTitle(info?.title),
      title: info?.title || null,
      parentID: info?.parentID || null,
    };
    sessionMetaCache.set(sessionID, meta);
    return meta;
  } catch {
    return { isBackground: false };
  }
};

const shouldIgnoreBackgroundEvent = async (event, client) => {
  const sessionID = extractSessionID(event);
  if (!sessionID) {
    return false;
  }

  const meta = await getSessionMeta(sessionID, client);
  return meta.isBackground;
};

const buildTitleCandidate = (prompt) => {
  if (!prompt) {
    return null;
  }

  const cleaned = cleanSnippet(prompt);
  if (!cleaned) {
    return null;
  }

  const firstSentence = cleaned.split(/[.!?]/).map((line) => line.trim()).find(Boolean) || cleaned;
  const words = firstSentence.split(/\s+/);
  if (words.length < TITLE_MIN_WORDS && firstSentence.length < 12) {
    return null;
  }

  let candidate = firstSentence;
  if (candidate.length > TITLE_MAX_LENGTH) {
    candidate = `${candidate.slice(0, TITLE_MAX_LENGTH - 1).replace(/[,;:\-]+$/, "").trim()}…`;
  }

  return candidate.replace(/^[a-z]/, (char) => char.toUpperCase());
};

const maybeAutoRenameSession = async (event, client) => {
  if (!client || event.type !== "message.updated") {
    return;
  }

  const message = event.properties?.info;
  if (!message || message.role !== "user" || !message.sessionID) {
    return;
  }

  const sessionMeta = await getSessionMeta(message.sessionID, client);
  if (sessionMeta.isBackground) {
    return;
  }

  if (autoNamedSessions.has(message.sessionID) || renameInFlight.has(message.sessionID)) {
    return;
  }

  const prompt = extractUserPrompt(message);
  const candidate = buildTitleCandidate(prompt);
  if (!candidate) {
    return;
  }

  renameInFlight.add(message.sessionID);
  try {
    const sessionResponse = await client.session.get({
      path: { id: message.sessionID },
    });
    const sessionInfo = sessionResponse?.data;
    const currentTitle = sessionInfo?.title;

    if (!shouldUpdateTitle(currentTitle, candidate)) {
      return;
    }

    await client.session.update({
      path: { id: message.sessionID },
      body: { title: candidate },
    });
    autoNamedSessions.add(message.sessionID);
  } catch (error) {
    console.warn("Failed to auto-rename session", error);
  } finally {
    renameInFlight.delete(message.sessionID);
  }
};

export const NotificationPlugin = async ({ client }) => {
  return {
    event: async ({ event }) => {
      await maybeAutoRenameSession(event, client);
      if (!isTmuxSession()) {
        return;
      }
      if (await shouldIgnoreBackgroundEvent(event, client)) {
        return;
      }
      await handleTmuxAttention(event);
      const message = resolveMessage(event);

      if (CMUX_NOTIFY_EVENTS.has(event.type)) {
        await sendCmuxNotification(event, message);
      } else {
        await setCmuxStatusIconOnly(STATUS_ICON_BY_EVENT[event.type]);
      }

      const shouldForceSpeak = event.type === "permission.asked";
      if ((ENABLE_SPEECH || shouldForceSpeak) && shouldSpeakEvent(event.type, message)) {
        speak(message);
      }
    },
  };
};
