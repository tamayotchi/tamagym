defmodule Tamagym.AI do
  @moduledoc "Provider-neutral access to the language models enabled for Tamagym."

  require Logger

  @type model :: String.t()
  @type schema :: map()

  @callback generate_object(model(), String.t(), String.t(), schema(), keyword()) ::
              {:ok, map()} | {:error, term()}

  def models do
    configured = Application.get_env(:tamagym, :ai_models, []) |> List.wrap()

    models =
      if configured == [] do
        System.get_env("AI_MODELS", System.get_env("AI_MODEL", ""))
        |> String.split(",", trim: true)
      else
        configured
      end

    models
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  def configured?, do: models() != []
  def model_allowed?(model), do: to_string(model) in models()

  def selected_model(state) when is_map(state) do
    configured = models()
    selected = state["aiModel"]

    if selected in configured, do: selected, else: List.first(configured)
  end

  def generate_object(model, system_prompt, prompt, schema, opts \\ []) do
    {operation, client_opts} = Keyword.pop(opts, :operation, :structured_object)
    client = client()
    started_at = System.monotonic_time(:millisecond)

    Logger.info(
      "[Tamagym.AI] request started operation=#{operation} model=#{model} client=#{inspect(client)}"
    )

    result = client.generate_object(model, system_prompt, prompt, schema, client_opts)
    duration = System.monotonic_time(:millisecond) - started_at

    case result do
      {:ok, object} when is_map(object) ->
        Logger.info(
          "[Tamagym.AI] request succeeded operation=#{operation} model=#{model} duration_ms=#{duration}"
        )

      {:error, reason} ->
        Logger.error(
          "[Tamagym.AI] request failed operation=#{operation} model=#{model} duration_ms=#{duration} reason=#{error_summary(reason)}"
        )

      other ->
        Logger.error(
          "[Tamagym.AI] request returned an unexpected value operation=#{operation} model=#{model} duration_ms=#{duration} result=#{error_summary(other)}"
        )
    end

    result
  rescue
    exception ->
      Logger.error(
        "[Tamagym.AI] request crashed model=#{model} reason=#{error_summary(exception)}"
      )

      {:error, exception}
  end

  @doc false
  def error_summary(reason) do
    reason
    |> summarize_error()
    |> redact_secrets()
    |> String.slice(0, 2_000)
  end

  defp summarize_error(%{__exception__: true} = exception) do
    "#{inspect(exception.__struct__)}: #{Exception.message(exception)}"
  rescue
    _exception -> inspect(exception.__struct__)
  end

  defp summarize_error(reason) when is_tuple(reason) do
    reason
    |> Tuple.to_list()
    |> Enum.map_join(" ", &summarize_error/1)
  end

  defp summarize_error(reason) when is_list(reason) do
    reason
    |> Enum.take(10)
    |> Enum.map_join(", ", &summarize_error/1)
  end

  defp summarize_error(%{} = reason) do
    label = if module = reason[:__struct__], do: inspect(module), else: "map"

    details =
      [:status, :provider_code, :tag, :reason, :message, :missing, :parameter]
      |> Enum.filter(&Map.has_key?(reason, &1))
      |> Enum.map_join(" ", fn key -> "#{key}=#{summarize_error(reason[key])}" end)

    if details == "", do: label, else: "#{label} #{details}"
  end

  defp summarize_error(reason) when is_binary(reason), do: reason
  defp summarize_error(reason) when is_atom(reason) or is_number(reason), do: to_string(reason)
  defp summarize_error(reason), do: inspect(reason, limit: 20, printable_limit: 500)

  defp redact_secrets(message) do
    message
    |> String.replace(~r/AIza[0-9A-Za-z_-]{20,}/, "[REDACTED_GOOGLE_KEY]")
    |> String.replace(~r/sk-[0-9A-Za-z_-]{16,}/, "[REDACTED_API_KEY]")
    |> String.replace(~r/(?i)(bearer\s+)[^\s,]+/, "\\1[REDACTED]")
    |> String.replace(~r/(?i)((?:api[_-]?key|key)\s*[=:]\s*)[^\s,&]+/, "\\1[REDACTED]")
  end

  defp client do
    Application.get_env(:tamagym, :ai_client, Tamagym.AI.ReqLLM)
  end
end
