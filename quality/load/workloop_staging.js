import http from "k6/http";
import { check, fail, sleep } from "k6";
import { Counter, Rate } from "k6/metrics";

const criticalFailures = new Rate("critical_workflow_failures");
const duplicateWrites = new Counter("duplicate_write_attempts");
const profile = __ENV.LOAD_PROFILE || "smoke";

const profiles = {
  smoke: [
    { duration: "20s", target: 10 },
    { duration: "40s", target: 10 },
    { duration: "20s", target: 0 },
  ],
  baseline: [
    { duration: "2m", target: 100 },
    { duration: "5m", target: 100 },
    { duration: "2m", target: 0 },
  ],
  moderate: [
    { duration: "5m", target: 500 },
    { duration: "10m", target: 500 },
    { duration: "5m", target: 0 },
  ],
  high: [
    { duration: "10m", target: 1000 },
    { duration: "15m", target: 1000 },
    { duration: "10m", target: 0 },
  ],
  stress: [
    { duration: "15m", target: 5000 },
    { duration: "15m", target: 5000 },
    { duration: "15m", target: 0 },
  ],
};

if (!profiles[profile]) {
  throw new Error(`Unknown LOAD_PROFILE "${profile}"`);
}

export const options = {
  scenarios: {
    workloop: {
      executor: "ramping-vus",
      gracefulRampDown: "30s",
      stages: profiles[profile],
    },
  },
  thresholds: {
    critical_workflow_failures: ["rate<0.01"],
    http_req_failed: ["rate<0.01"],
    "http_req_duration{operation:read}": ["p(95)<1000"],
    "http_req_duration{operation:write}": ["p(95)<2000"],
  },
};

const productionProjectRef = "imtbyrvsonzvtddswbtb";

export function setup() {
  const target = (__ENV.SUPABASE_URL || "").trim();
  if (
    __ENV.LOAD_TEST_ENV !== "staging" || __ENV.ALLOW_STAGING_LOAD !== "true"
  ) {
    fail(
      "Refusing to run: set LOAD_TEST_ENV=staging and " +
        "ALLOW_STAGING_LOAD=true after verifying the isolated target.",
    );
  }
  if (
    !target.startsWith("https://") && !target.startsWith("http://127.0.0.1")
  ) {
    fail("SUPABASE_URL must be HTTPS or loopback.");
  }
  const lowered = target.toLowerCase();
  if (
    lowered.includes(productionProjectRef) ||
    lowered.includes("workloop.app") ||
    lowered.includes("workloop.uk") ||
    lowered.includes("workloop.co.uk")
  ) {
    fail("Refusing to run against the known Workloop production target.");
  }
  if (!__ENV.SUPABASE_ANON_KEY) {
    fail("SUPABASE_ANON_KEY is required.");
  }
  if (profile !== "smoke" && __ENV.CONFIRM_STAGING_COST !== "true") {
    fail("Non-smoke profiles require CONFIRM_STAGING_COST=true.");
  }
  return { target };
}

export default function (data) {
  const operation = (__ITER + __VU) % 5;
  if (operation === 0) {
    normalDailyActivity(data.target);
  } else if (operation === 1) {
    morningReadSpike(data.target);
  } else if (operation === 2) {
    bookingSpike(data.target);
  } else if (operation === 3) {
    financeActivity(data.target);
  } else {
    notificationReads(data.target);
  }
  sleep(0.3 + ((__VU % 7) / 10));
}

function headers(authenticated = true) {
  const result = {
    apikey: __ENV.SUPABASE_ANON_KEY,
    "Content-Type": "application/json",
    "X-Workloop-Load-Test": "staging-only",
  };
  if (authenticated && __ENV.TEST_ACCESS_TOKEN) {
    result.Authorization = `Bearer ${__ENV.TEST_ACCESS_TOKEN}`;
  }
  return result;
}

function read(target, path, name) {
  const response = http.get(`${target}/rest/v1/${path}`, {
    headers: headers(),
    tags: { operation: "read", scenario_name: name },
  });
  record(response, name, [200, 206]);
  return response;
}

function write(target, table, body, name) {
  const response = http.post(
    `${target}/rest/v1/${table}`,
    JSON.stringify(body),
    {
      headers: {
        ...headers(),
        Prefer: "return=minimal",
      },
      tags: { operation: "write", scenario_name: name },
    },
  );
  record(response, name, [201]);
  return response;
}

function normalDailyActivity(target) {
  requireReadIdentity();
  const workspace = encodeURIComponent(`eq.${__ENV.WORKSPACE_ID}`);
  read(
    target,
    `contacts?select=id,name,status&workspace_id=${workspace}&limit=50`,
    "client_search",
  );
  read(
    target,
    `appointments?select=id,start_time,end_time,status&workspace_id=${workspace}` +
      "&order=start_time.asc&limit=50",
    "bookings",
  );
}

function morningReadSpike(target) {
  requireReadIdentity();
  const workspace = encodeURIComponent(`eq.${__ENV.WORKSPACE_ID}`);
  read(
    target,
    `appointments?select=id,start_time,status&workspace_id=${workspace}&limit=20`,
    "morning_bookings",
  );
  read(
    target,
    `tasks?select=id,title,status,due_date&workspace_id=${workspace}&limit=50`,
    "morning_tasks",
  );
  read(
    target,
    `notifications?select=id,read_at&workspace_id=${workspace}&limit=25`,
    "morning_notifications",
  );
}

function bookingSpike(target) {
  if (__ENV.BOOKING_WRITE_ENABLED !== "true") {
    if (__ENV.PUBLIC_HANDLE) {
      const response = http.get(
        `${target}/functions/v1/get-public-profile?handle=` +
          encodeURIComponent(__ENV.PUBLIC_HANDLE),
        {
          headers: headers(false),
          tags: { operation: "read", scenario_name: "public_profile" },
        },
      );
      record(response, "public_profile", [200]);
    }
    return;
  }
  if (!__ENV.PUBLIC_HANDLE || !__ENV.SERVICE_ID) {
    fail("Booking writes require PUBLIC_HANDLE and SERVICE_ID.");
  }
  const token = deterministicUuid(__VU, __ITER);
  const payload = {
    handle: __ENV.PUBLIC_HANDLE,
    name: `Load Fixture ${__VU}`,
    phone: `+447700${String(900000 + (__VU % 99999)).padStart(6, "0")}`,
    service_id: __ENV.SERVICE_ID,
    preferred_time_text: "Staging load test only",
    message: "Synthetic isolated booking request",
    request_token: token,
  };
  const url = `${target}/functions/v1/create-booking-request`;
  const params = {
    headers: headers(false),
    tags: { operation: "write", scenario_name: "booking_request" },
  };
  const first = http.post(url, JSON.stringify(payload), params);
  record(first, "booking_request", [200, 429]);

  if ((__ITER + __VU) % 20 === 0) {
    duplicateWrites.add(1);
    const duplicate = http.post(url, JSON.stringify(payload), params);
    record(duplicate, "booking_idempotency_retry", [200, 429]);
  }
}

function financeActivity(target) {
  requireReadIdentity();
  const workspace = encodeURIComponent(`eq.${__ENV.WORKSPACE_ID}`);
  read(
    target,
    `payments?select=id,amount,status,payment_date&workspace_id=${workspace}` +
      "&order=payment_date.desc&limit=50",
    "finance_summary",
  );
  read(
    target,
    `expenses?select=id,amount,category,expense_date&workspace_id=${workspace}` +
      "&order=expense_date.desc&limit=50",
    "expense_summary",
  );
  if (__ENV.FINANCE_WRITE_ENABLED === "true") {
    write(
      target,
      "expenses",
      {
        workspace_id: __ENV.WORKSPACE_ID,
        amount: 1.01,
        category: "staging-load-test",
        description: `Synthetic k6 expense ${__VU}-${__ITER}`,
        expense_date: "2026-07-26",
      },
      "finance_write",
    );
  }
}

function notificationReads(target) {
  requireReadIdentity();
  const workspace = encodeURIComponent(`eq.${__ENV.WORKSPACE_ID}`);
  read(
    target,
    `notifications?select=id,title,read_at&workspace_id=${workspace}` +
      "&order=created_at.desc&limit=50",
    "notification_reconnect",
  );
}

function requireReadIdentity() {
  if (!__ENV.TEST_ACCESS_TOKEN || !__ENV.WORKSPACE_ID) {
    fail("Authenticated scenarios require TEST_ACCESS_TOKEN and WORKSPACE_ID.");
  }
}

function record(response, name, expectedStatuses) {
  const ok = check(response, {
    [`${name} returned an expected status`]: (result) =>
      expectedStatuses.includes(result.status),
  });
  criticalFailures.add(!ok);
}

function deterministicUuid(vu, iteration) {
  const tail = String(vu * 1000000 + iteration).padStart(12, "0").slice(-12);
  return `00000000-0000-4000-8000-${tail}`;
}
