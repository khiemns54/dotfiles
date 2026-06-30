import assert from "node:assert/strict";
import test from "node:test";
import { createCmuxNotifyPlugin } from "./cmux-notify.js";

const makeClient = ({ title = "Session Alpha", parentID = null } = {}) => ({
  session: {
    get: async () => ({
      data: {
        title,
        parentID,
      },
    }),
  },
});

test("permission.asked updates description, status, notifies, and speaks", async () => {
  const calls = [];
  const plugin = await createCmuxNotifyPlugin({
    client: makeClient(),
    exec: (command, args, callback) => {
      calls.push({ command, args });
      callback(null, "", "");
    },
    now: () => 1000,
  });

  await plugin.event({
    event: {
      type: "permission.asked",
      properties: {
        sessionID: "s1",
        title: "Need approval",
      },
    },
  });

  assert.ok(calls.length >= 5);
  assert.equal(calls[0].args[0], "workspace-action");
  assert.equal(calls[0].args[1], "--action");
  assert.equal(calls[0].args[2], "editWorkspaceDescription");
  assert.equal(calls[0].args[3], "--description");
  assert.equal(calls[0].args[4], "Session Alpha");
  const clearStatusCall = calls.find((entry) => entry.command === "cmux" && entry.args[0] === "clear-status");
  assert.ok(clearStatusCall);
  assert.deepEqual(clearStatusCall.args, ["clear-status", "opencode_session"]);

  const setStatusCall = calls.find((entry) => entry.command === "cmux" && entry.args[0] === "set-status");
  assert.ok(setStatusCall);
  assert.deepEqual(setStatusCall.args, [
    "set-status",
    "opencode_session",
    "\u00A0",
    "--icon",
    "shield-alert",
  ]);
  const notifyCall = calls.find((entry) => entry.command === "cmux" && entry.args[0] === "notify");
  assert.ok(notifyCall);
  const sayCall = calls.find((entry) => entry.command === "say");
  assert.ok(sayCall);
});

test("workspace description is not updated when session title is unavailable", async () => {
  const calls = [];
  const plugin = await createCmuxNotifyPlugin({
    client: {
      session: {
        get: async () => ({
          data: {
            title: null,
            parentID: null,
          },
        }),
      },
    },
    exec: (command, args, callback) => {
      calls.push({ command, args });
      callback(null, "", "");
    },
    now: () => 1500,
  });

  await plugin.event({
    event: {
      type: "message.updated",
      properties: {
        sessionID: "s4",
        info: {
          title: "Session From Event",
          role: "assistant",
        },
      },
    },
  });

  const workspaceAction = calls.find((entry) => entry.command === "cmux" && entry.args[0] === "workspace-action");
  assert.equal(workspaceAction, undefined);
});

test("session.idle sends done notification for main session", async () => {
  const calls = [];
  const plugin = await createCmuxNotifyPlugin({
    client: makeClient({ title: "Session Beta", parentID: null }),
    exec: (command, args, callback) => {
      calls.push({ command, args });
      callback(null, "", "");
    },
    now: () => 2000,
  });

  await plugin.event({
    event: {
      type: "session.idle",
      properties: {
        sessionID: "s2",
      },
    },
  });

  const notifyCall = calls.find((entry) => entry.command === "cmux" && entry.args[0] === "notify");
  assert.ok(notifyCall);
  assert.ok(notifyCall.args.includes("Task done"));

  const statusCall = calls.find((entry) => entry.command === "cmux" && entry.args[0] === "set-status");
  assert.equal(statusCall, undefined);

  const clearStatusCall = calls.find((entry) => entry.command === "cmux" && entry.args[0] === "clear-status");
  assert.ok(clearStatusCall);

});

test("background session idle does not send done notification", async () => {
  const calls = [];
  const plugin = await createCmuxNotifyPlugin({
    client: makeClient({ title: "Background", parentID: "parent-1" }),
    exec: (command, args, callback) => {
      calls.push({ command, args });
      callback(null, "", "");
    },
    now: () => 3000,
  });

  await plugin.event({
    event: {
      type: "session.idle",
      properties: {
        sessionID: "s3",
      },
    },
  });

  const notifyCalls = calls.filter((entry) => entry.command === "cmux" && entry.args[0] === "notify");
  assert.equal(notifyCalls.length, 0);
});

test("assistant message.updated does not alter status", async () => {
  const calls = [];
  const plugin = await createCmuxNotifyPlugin({
    client: makeClient({ title: "Session Gamma", parentID: null }),
    exec: (command, args, callback) => {
      calls.push({ command, args });
      callback(null, "", "");
    },
    now: () => 4000,
  });

  await plugin.event({
    event: {
      type: "session.idle",
      properties: {
        sessionID: "s5",
      },
    },
  });

  const before = calls.length;
  await plugin.event({
    event: {
      type: "message.updated",
      properties: {
        sessionID: "s5",
        info: {
          role: "assistant",
          title: "Task done",
        },
      },
    },
  });

  const newCalls = calls.slice(before);
  const setStatusCalls = newCalls.filter((entry) => entry.command === "cmux" && entry.args[0] === "set-status");
  assert.equal(setStatusCalls.length, 0);
  const clearStatusCalls = newCalls.filter((entry) => entry.command === "cmux" && entry.args[0] === "clear-status");
  assert.equal(clearStatusCalls.length, 0);
});

test("status does not switch to Working on question.replied after Task done", async () => {
  const calls = [];
  const plugin = await createCmuxNotifyPlugin({
    client: makeClient({ title: "Session Delta", parentID: null }),
    exec: (command, args, callback) => {
      calls.push({ command, args });
      callback(null, "", "");
    },
    now: () => 6000,
  });

  await plugin.event({
    event: {
      type: "session.idle",
      properties: { sessionID: "s7" },
    },
  });

  const before = calls.length;
  await plugin.event({
    event: {
      type: "question.replied",
      properties: { sessionID: "s7" },
    },
  });

  const afterCalls = calls.slice(before);
  const setStatusCalls = afterCalls.filter((entry) => entry.command === "cmux" && entry.args[0] === "set-status");
  assert.equal(setStatusCalls.length, 0);
});

test("workspace description update targets CMUX_WORKSPACE_ID", async () => {
  const originalWorkspace = process.env.CMUX_WORKSPACE_ID;
  process.env.CMUX_WORKSPACE_ID = "workspace:2";

  const calls = [];
  const plugin = await createCmuxNotifyPlugin({
    client: makeClient({ title: "Named Session", parentID: null }),
    exec: (command, args, callback) => {
      calls.push({ command, args });
      callback(null, "", "");
    },
    now: () => 5000,
  });

  await plugin.event({
    event: {
      type: "question.asked",
      properties: {
        sessionID: "s6",
      },
    },
  });

  const workspaceAction = calls.find((entry) => entry.command === "cmux" && entry.args[0] === "workspace-action");
  assert.ok(workspaceAction);
  assert.ok(workspaceAction.args.includes("--workspace"));
  assert.ok(workspaceAction.args.includes("workspace:2"));

  if (originalWorkspace === undefined) {
    delete process.env.CMUX_WORKSPACE_ID;
  } else {
    process.env.CMUX_WORKSPACE_ID = originalWorkspace;
  }
});

test("session metadata title is used for workspace description", async () => {
  const calls = [];
  const plugin = await createCmuxNotifyPlugin({
    client: makeClient({ title: "Session Name", parentID: null }),
    exec: (command, args, callback) => {
      calls.push({ command, args });
      callback(null, "", "");
    },
    now: () => 7000,
  });

  await plugin.event({
    event: {
      type: "message.updated",
      properties: {
        sessionID: "s8",
        info: {
          role: "user",
          title: "Ignored Event Title",
        },
      },
    },
  });

  const workspaceAction = calls.find((entry) => entry.command === "cmux" && entry.args[0] === "workspace-action");
  assert.ok(workspaceAction);
  assert.equal(workspaceAction.args[4], "Session Name");
});
