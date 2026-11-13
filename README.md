# Hermetica Elixir client

Generated from `docs/api/openapi.json` by `node scripts/gen-sdks.mjs` (2524 operations). Uses [Req](https://hex.pm/packages/req).

```elixir
def deps, do: [{:hermeticacomms, "~> 0.4.0"}]
```

```elixir
hm = Hermetica.new("hm_sk_...", "https://api.example.com")
{:ok, page} = Hermetica.Api.get_v1_profiles(hm, query: %{limit: 25})
{:ok, _} = Hermetica.Api.post_v1_events(hm,
  body: %{name: "signed_up", profile: %{email: "ada@example.com"}},
  idempotency_key: "signup-ada-1")
{:ok, all} = Hermetica.list_all(hm, &Hermetica.Api.get_v1_profiles/2) # follows nextCursor
```

- One function per operationId (snake_case) in `Hermetica.Api`. Results are decoded JSON; errors are `{:error, %Hermetica.Error{}}` with
  status, code, message, details (status 0 for a network error).
- Every non-GET call sends an `Idempotency-Key` (random unless you set one); reuse yours when you retry a call yourself.
- Network errors, 429 and 5xx are retried with exponential backoff and jitter, honouring a `Retry-After` in seconds. Every attempt sends
  the same `Idempotency-Key`, so a retried write never runs twice. `max_retries` is 3: `Hermetica.new(key, url, max_retries: 0)` turns retries off.
- Consent and suppression are enforced by the API; the client cannot bypass them.
- Regenerate after the API changes: `node scripts/gen-sdks.mjs`.
