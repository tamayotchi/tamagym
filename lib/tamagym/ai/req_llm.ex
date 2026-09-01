defmodule Tamagym.AI.ReqLLM do
  @moduledoc "ReqLLM-backed AI client. The provider is selected by the model specification."

  @behaviour Tamagym.AI

  @impl true
  def generate_object(model, system_prompt, prompt, schema, opts) do
    options =
      opts
      |> Keyword.put(:system_prompt, system_prompt)
      |> Keyword.put_new(:temperature, 0.2)
      |> Keyword.put_new(:receive_timeout, 120_000)
      |> Keyword.put_new(:total_timeout, 150_000)
      |> Keyword.put_new(:output_validation, :strict)

    with {:ok, response} <- ReqLLM.generate_object(model, prompt, schema, options),
         object when is_map(object) <- ReqLLM.Response.object(response) do
      {:ok, object}
    else
      nil -> {:error, :empty_structured_response}
      {:error, reason} -> {:error, reason}
      other -> {:error, {:unexpected_structured_response, other}}
    end
  rescue
    exception -> {:error, exception}
  end
end
