defmodule HermeticaTest do
  use ExUnit.Case, async: true

  # Answers the nth request with statuses[n] (Retry-After: 0 on errors) and sends each request to the test process.
  defp client(statuses) do
    test = self()
    {:ok, counter} = Agent.start_link(fn -> statuses end)

    Req.Test.stub(__MODULE__, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      send(test, {:req, conn.method, conn.request_path, conn.query_string, Plug.Conn.get_req_header(conn, "idempotency-key"), body})
      status = Agent.get_and_update(counter, fn [s | rest] -> {s, rest}; [] -> {200, []} end)
      conn = if status >= 300, do: Plug.Conn.put_resp_header(conn, "retry-after", "0"), else: conn
      body = if status == 404, do: %{error: %{code: "not_found", message: "nope"}}, else: %{ok: true}
      conn |> Plug.Conn.put_status(status) |> Req.Test.json(body)
    end)

    Hermetica.new("hm_sk_test", "https://api.test/", req_options: [plug: {Req.Test, __MODULE__}])
  end

  test "retries with the same idempotency key" do
    hm = client([503, 429, 200])
    assert {:ok, %{"ok" => true}} = Hermetica.Api.post_v1_profiles(hm, body: %{email: "a@b.co"})
    keys = for _ <- 1..3, do: (assert_received({:req, "POST", "/v1/profiles", _, [k], ~s({"email":"a@b.co"})}); k)
    assert [k, k, k] = keys
    refute_received {:req, _, _, _, _, _}
  end

  test "does not retry 4xx and reads the error" do
    hm = client([404])
    assert {:error, %Hermetica.Error{status: 404, code: "not_found", message: "nope"}} = Hermetica.Api.get_healthz(hm)
    assert_received {:req, "GET", "/healthz", _, [], _}
    refute_received {:req, _, _, _, _, _}
  end

  test "gives up after max_retries" do
    hm = %{client([502, 502, 502]) | max_retries: 1}
    assert {:error, %Hermetica.Error{status: 502}} = Hermetica.Api.get_healthz(hm)
  end

  test "path params are encoded, query nils dropped, and a missing one is an error" do
    hm = client([])
    assert {:error, %Hermetica.Error{code: "invalid"}} = Hermetica.request(hm, "GET", "/v1/profiles/{id}")
    assert {:ok, _} = Hermetica.request(hm, "GET", "/v1/profiles/{id}", path: %{id: "a b"}, query: %{limit: 5, cursor: nil})
    assert_received {:req, "GET", "/v1/profiles/a%20b", "limit=5", _, _}
  end
end
