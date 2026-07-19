import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  unitSearchFrom,
  withUnitLabel,
} from "./address_unit.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const googlePlacesBaseUrl = "https://places.googleapis.com/v1";

type RequestPayload = {
  action?: unknown;
  input?: unknown;
  placeId?: unknown;
  sessionToken?: unknown;
};

type AddressPrediction = {
  placeId: string;
  fullText: string;
  primaryText: string;
  secondaryText: string;
  unitLabel: string;
  isPostcode: boolean;
};

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function stringValue(value: unknown, maxLength: number) {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, maxLength);
}

async function authenticatedUser(req: Request) {
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const authorization = req.headers.get("Authorization") ?? "";
  if (!supabaseUrl || !anonKey || !authorization) return null;

  const client = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await client.auth.getUser();
  if (error) return null;
  return data.user;
}

async function googleAutocomplete(
  input: string,
  sessionToken: string,
  apiKey: string,
  unitLabel: string,
): Promise<AddressPrediction[]> {
  const googleResponse = await fetch(
    `${googlePlacesBaseUrl}/places:autocomplete`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask": [
          "suggestions.placePrediction.placeId",
          "suggestions.placePrediction.text.text",
          "suggestions.placePrediction.structuredFormat.mainText.text",
          "suggestions.placePrediction.structuredFormat.secondaryText.text",
          "suggestions.placePrediction.types",
        ].join(","),
      },
      body: JSON.stringify({
        input,
        sessionToken,
        // Google expects ccTLD values here. The United Kingdom is `uk`
        // (rather than its ISO 3166-1 code, `gb`).
        includedRegionCodes: ["uk"],
        regionCode: "uk",
        languageCode: "en-GB",
        includeQueryPredictions: false,
      }),
    },
  );

  if (!googleResponse.ok) {
    const responseBody = await googleResponse.text();
    console.error(
      "Google Places autocomplete failed",
      googleResponse.status,
      responseBody,
    );
    throw new Error(
      `Google Places autocomplete failed: ${googleResponse.status}`,
    );
  }

  const result = await googleResponse.json();
  const suggestions = Array.isArray(result.suggestions)
    ? result.suggestions
    : [];
  return suggestions.flatMap((item: Record<string, unknown>) => {
    const prediction = item.placePrediction as
      | Record<string, unknown>
      | undefined;
    if (!prediction) return [];
    const text = prediction.text as Record<string, unknown> | undefined;
    const structured = prediction.structuredFormat as
      | Record<string, unknown>
      | undefined;
    const mainText = structured?.mainText as
      | Record<string, unknown>
      | undefined;
    const secondaryText = structured?.secondaryText as
      | Record<string, unknown>
      | undefined;
    const placeId = stringValue(prediction.placeId, 256);
    const fullText = stringValue(text?.text, 500);
    const types = Array.isArray(prediction.types)
      ? prediction.types.filter((value): value is string =>
        typeof value === "string"
      )
      : [];
    if (!placeId || !fullText) return [];
    return [{
      placeId,
      fullText: withUnitLabel(fullText, unitLabel),
      primaryText: withUnitLabel(
        stringValue(mainText?.text, 240) || fullText,
        unitLabel,
      ),
      secondaryText: stringValue(secondaryText?.text, 300),
      unitLabel,
      isPostcode: types.includes("postal_code") ||
        types.includes("postal_code_prefix"),
    }];
  });
}

async function autocomplete(
  input: string,
  sessionToken: string,
  apiKey: string,
) {
  const unitSearch = unitSearchFrom(input);
  const searches = [unitSearch?.buildingInput, input];
  const uniqueSearches = [...new Set(
    searches.filter((value): value is string => Boolean(value)),
  )];

  try {
    const resultSets = await Promise.all(
      uniqueSearches.map((query) =>
        googleAutocomplete(
          query,
          sessionToken,
          apiKey,
          unitSearch?.unitLabel ?? "",
        )
      ),
    );
    const seen = new Set<string>();
    const predictions = resultSets
      .flat()
      .filter((prediction) => {
        if (seen.has(prediction.placeId)) return false;
        seen.add(prediction.placeId);
        return true;
      })
      .slice(0, 5);

    return jsonResponse(200, { predictions });
  } catch (_) {
    return jsonResponse(502, { error: "Address suggestions are unavailable" });
  }
}

async function details(
  placeId: string,
  sessionToken: string,
  apiKey: string,
) {
  const query = new URLSearchParams({
    sessionToken,
    languageCode: "en-GB",
    regionCode: "uk",
  });
  const googleResponse = await fetch(
    `${googlePlacesBaseUrl}/places/${encodeURIComponent(placeId)}?${query}`,
    {
      headers: {
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask": "formattedAddress,location",
      },
    },
  );

  if (!googleResponse.ok) {
    console.error(
      "Google Places details failed",
      googleResponse.status,
      await googleResponse.text(),
    );
    return jsonResponse(502, { error: "Could not load the selected address" });
  }

  const result = await googleResponse.json();
  const formattedAddress = stringValue(result.formattedAddress, 500);
  if (!formattedAddress) {
    return jsonResponse(502, {
      error: "Google returned an incomplete address",
    });
  }

  return jsonResponse(200, {
    formattedAddress,
    latitude: typeof result.location?.latitude === "number"
      ? result.location.latitude
      : null,
    longitude: typeof result.location?.longitude === "number"
      ? result.location.longitude
      : null,
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  if (!await authenticatedUser(req)) {
    return jsonResponse(401, { error: "Unauthorized" });
  }

  const apiKey = Deno.env.get("GOOGLE_PLACES_API_KEY") ?? "";
  if (!apiKey) {
    return jsonResponse(503, { error: "Address search is not configured" });
  }

  let payload: RequestPayload;
  try {
    payload = await req.json();
  } catch (_) {
    return jsonResponse(400, { error: "Invalid request body" });
  }

  const action = stringValue(payload.action, 32);
  const sessionToken = stringValue(payload.sessionToken, 128);
  if (!sessionToken) {
    return jsonResponse(400, { error: "Missing search session" });
  }

  if (action === "autocomplete") {
    const input = stringValue(payload.input, 240);
    if (input.length < 3) return jsonResponse(200, { predictions: [] });
    return autocomplete(input, sessionToken, apiKey);
  }

  if (action === "details") {
    const placeId = stringValue(payload.placeId, 256);
    if (!placeId || !/^[A-Za-z0-9_-]+$/.test(placeId)) {
      return jsonResponse(400, { error: "Invalid place" });
    }
    return details(placeId, sessionToken, apiKey);
  }

  return jsonResponse(400, { error: "Unsupported address action" });
});
