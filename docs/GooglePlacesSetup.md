# Google Places Address Search Setup

Last updated: 2026-07-18

Workloop uses Google Places API (New) for UK booking-address autocomplete in
Add Client and Edit Client. The mobile app calls the authenticated Supabase
Edge Function `places-address-search`; the Google API key is never bundled in
Flutter.

## One-time Google Cloud setup

1. Create or select the Google Cloud project used by Workloop.
2. Attach a billing account. Google requires billing even when usage remains
   inside its monthly free usage caps.
3. Enable **Places API (New)**.
4. Create a dedicated API key named `Workloop Places server`.
5. Under API restrictions, restrict the key to **Places API (New)** only.
6. Set conservative request quotas for Autocomplete and Place Details, and add
   Cloud Billing budget alerts. Budget alerts notify; API quotas are the usage
   control.

The Edge Function runs on managed infrastructure with changing outbound IPs,
so an IP application restriction is not applied. The key is instead protected
by Supabase secrets, authenticated function access, input limits, API
restriction, and Google quotas.

## Supabase setup

Set the key as an Edge Function secret:

```bash
supabase secrets set GOOGLE_PLACES_API_KEY=YOUR_KEY
supabase functions deploy places-address-search
```

Do not add the Google key to the Flutter `.env` file. For local Edge Function
testing, copy `supabase/functions/.env.example` to an ignored local env file and
run the function with that env file.

## Runtime behaviour

- Search begins after three characters and is debounced.
- Results are restricted to the United Kingdom and returned in British English.
- Flat, apartment, unit, and suite searches also query the building-level
  address. Workloop preserves the typed unit label when the selected Google
  Place represents only the building.
- Users start with the first line of an address for the most dependable
  suggestions. Address entry remains one field, and a postcode or other manual
  location can be saved without selecting a suggestion.
- Suggestion rows share the text field's tap region, so selecting or scrolling
  results does not dismiss them. The result list has its own bounded scroll
  area, remains present while the surrounding form is repositioned, and has an
  explicit Close action.
- A selected suggestion is applied immediately, then replaced by Google's
  canonical formatted address when Place Details succeeds. Manual text remains
  usable if the details request is unavailable.
- Autocomplete calls and the selected Place Details call share a session token.
- Only the suggestion text, place ID, formatted address, and coordinates are
  requested.
- The selected formatted address is stored in the existing contact `address`
  field. Coordinates are returned by the service for a later schema decision,
  but are not persisted yet.
- If search is unavailable, users can continue entering the address manually.
- Google Maps attribution is displayed with the suggestion list.

Google Places is not a complete residential property directory and does not
enumerate every flat or household. Manual entry remains available whenever a
full address is not suggested.

## Follow-up before public release

- Ensure Workloop's public Terms of Use and Privacy Policy incorporate the
  required Google Maps Platform terms and privacy references.
- Review usage and quotas after real traffic is available.
