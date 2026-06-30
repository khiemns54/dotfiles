import { execFile } from "node:child_process";

const STATUS_KEY = "opencode_session";
const VOICE = "Ava";
const NOTIFY_COOLDOWN_MS = 15000;
const ICON_ONLY_STATUS_VALUE = "\u00A0";

const lastNotifiedAt = new Map();

const STATUS_BY_EVENT = {
  "message.updated": { value: ICON_ONLY_STATUS_VALUE, icon: "loader" },
  "permission.asked": { value: ICON_ONLY_STATUS_VALUE, icon: "shield-alert" },
  "question.asked": { value: ICON_ONLY_STATUS_VALUE, icon: "message-circle-question" },
  "session.error": { value: ICON_ONLY_STATUS_VALUE, icon: "triangle-alert" },
};

const ACTIONABLE_EVENTS = new Set([
  "message.updated",
  "permission.asked",
  "permission.replied",
  "question.asked",
  "question.replied",
  "session.error",
  "session.idle",
]);

const resolveStatusForEvent = (event) => {
  if (event?.type !== "message.updated") {
    return STATUS_BY_EVENT[event?.type] || null;
  }

  const role = event?.properties?.info?.role;
  if (role === "user") {
    return STATUS_BY_EVENT["message.updated"];
  }

  if (role === "assistant") {
    return null;
  }

  return null;
};

const execFileAsync = (command, args, execImpl) => {
  return new Promise((resolve, reject) => {
    execImpl(command, args, (error, stdout) => {
      if (error) {
        reject(error);
        return;
      }

      resolve((stdout || "").trim());
    });
  });
};

const extractSessionID = (event) => {
  return event?.properties?.sessionID || event?.properties?.info?.sessionID || event?.properties?.info?.id || null;
};

const looksBackgroundTitle = (title = "") => {
  return /\b(subtask|background|task run|agent task)\b/i.test(title);
};

const getSessionMeta = async (sessionID, client) => {
  if (!sessionID || !client) {
    return { title: null, isBackground: false };
  }

  try {
    const response = await client.session.get({ path: { id: sessionID } });
    const info = response?.data;
    return {
      title: info?.title || null,
      isBackground: Boolean(info?.parentID) || looksBackgroundTitle(info?.title),
    };
  } catch {
    return { title: null, isBackground: false };
  }
};

const shouldNotify = (key, now) => {
  const previous = lastNotifiedAt.get(key);
  if (previous && now - previous < NOTIFY_COOLDOWN_MS) {
    return false;
  }

  lastNotifiedAt.set(key, now);
  return true;
};

const formatPermissionMessage = (properties) => {
  if (!properties) {
    return "Permission requires your approval";
  }

  if (properties.title) {
    return `Permission required: ${properties.title}`;
  }

  if (properties.type) {
    return `Permission required for ${properties.type}`;
  }

  return "Permission requires your approval";
};

const runCmux = async (args, execImpl) => {
  try {
    await execFileAsync("cmux", args, execImpl);
  } catch {
    return;
  }
};

const runSay = async (message, execImpl) => {
  if (!message) {
    return;
  }

  try {
    await execFileAsync("say", ["--voice", VOICE, message], execImpl);
  } catch {
    return;
  }
};

const setWorkspaceDescription = async (title, execImpl) => {
  if (!title) {
    return;
  }

  const workspace = process.env.CMUX_WORKSPACE_ID;
  const workspaceArgs = workspace ? ["--workspace", workspace] : [];

  await runCmux([
    "workspace-action",
    "--action",
    "editWorkspaceDescription",
    "--description",
    title,
    ...workspaceArgs,
  ], execImpl);
};

const setSessionStatus = async ({ value, icon }, execImpl) => {
  await runCmux(["clear-status", STATUS_KEY], execImpl);
  await runCmux([
    "set-status",
    STATUS_KEY,
    value,
    "--icon",
    icon,
  ], execImpl);
};

const clearSessionStatus = async (execImpl) => {
  await runCmux(["clear-status", STATUS_KEY], execImpl);
};

const notifyPermission = async ({ sessionTitle, properties, execImpl, now }) => {
  const key = `permission.asked:${sessionTitle || "session"}`;
  if (!shouldNotify(key, now())) {
    return;
  }

  const body = formatPermissionMessage(properties);
  await runCmux([
    "notify",
    "--title",
    "OpenCode",
    "--subtitle",
    sessionTitle || "Session",
    "--body",
    body,
  ], execImpl);
  await runSay(body, execImpl);
};

const notifyTaskDone = async ({ sessionTitle, execImpl, now }) => {
  const key = `session.idle:${sessionTitle || "session"}`;
  if (!shouldNotify(key, now())) {
    return;
  }

  await runCmux([
    "notify",
    "--title",
    "OpenCode",
    "--subtitle",
    sessionTitle || "Session",
    "--body",
    "Task done",
  ], execImpl);
};

export const createCmuxNotifyPlugin = async ({ client, exec = execFile, now = () => Date.now() }) => {
  return {
    event: async ({ event }) => {
      if (!event || !ACTIONABLE_EVENTS.has(event.type)) {
        return;
      }

      const sessionID = extractSessionID(event);
      const sessionMeta = await getSessionMeta(sessionID, client);
      const sessionTitle = sessionMeta.title;

      await setWorkspaceDescription(sessionTitle, exec);

      if (sessionMeta.isBackground) {
        return;
      }

      const status = resolveStatusForEvent(event);

      if (event.type === "session.idle") {
        await clearSessionStatus(exec);
      } else if (status) {
        await setSessionStatus(status, exec);
      }

      if (event.type === "permission.asked") {
        await notifyPermission({
          sessionTitle,
          properties: event.properties,
          execImpl: exec,
          now,
        });
      }

      if (event.type === "session.idle") {
        await notifyTaskDone({
          sessionTitle,
          execImpl: exec,
          now,
        });
      }
    },
  };
};

export const CmuxNotifyPlugin = createCmuxNotifyPlugin;
