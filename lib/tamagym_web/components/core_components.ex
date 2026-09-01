defmodule TamagymWeb.CoreComponents do
  @moduledoc "Small, application-owned component set used by the LiveView UI."
  use Phoenix.Component

  attr :name, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def icon(assigns) do
    assigns = assign(assigns, :path, icon_path(assigns.name))

    ~H"""
    <svg
      class={["icn", @class]}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.8"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
      {@rest}
    >
      <path d={@path} />
    </svg>
    """
  end

  attr :field, Phoenix.HTML.FormField
  attr :id, :any, default: nil
  attr :name, :any, default: nil
  attr :label, :string, default: nil
  attr :type, :string, default: "text"
  attr :value, :any, default: nil
  attr :class, :string, default: nil
  attr :errors, :list, default: []
  attr :options, :list, default: []

  attr :rest, :global,
    include:
      ~w(accept autocomplete checked disabled form inputmode list max maxlength min minlength multiple pattern placeholder readonly required rows step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(
      field: nil,
      id: assigns.id || field.id,
      name: assigns.name || field.name,
      value: if(is_nil(assigns.value), do: field.value, else: assigns.value),
      errors: Enum.map(errors, &translate_error/1)
    )
    |> input()
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <label>
      <span :if={@label} class="sect-t">{@label}</span>
      <select name={@name} id={@id} class={@class || "input"} {@rest}>
        <option
          :for={{label, option_value} <- @options}
          value={option_value}
          selected={to_string(option_value) == to_string(@value)}
        >
          {label}
        </option>
      </select>
      <span :for={msg <- @errors} class="lv-error">{msg}</span>
    </label>
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <label class="row" style="gap:8px">
      <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
      <input
        type="checkbox"
        id={@id}
        name={@name}
        value="true"
        checked={@checked}
        class={@class}
        {@rest}
      />
      <span :if={@label}>{@label}</span>
    </label>
    """
  end

  def input(assigns) do
    ~H"""
    <label>
      <span :if={@label} class="sect-t">{@label}</span>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={@class || "input"}
        {@rest}
      />
      <span :for={msg <- @errors} class="lv-error">{msg}</span>
    </label>
    """
  end

  attr :type, :string, default: "button"
  attr :class, :string, default: nil
  attr :icon, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value phx-click phx-disable-with)
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button type={@type} class={@class || "btn primary"} {@rest}>
      <.icon :if={@icon} name={@icon} />
      <span>{render_slot(@inner_block)}</span>
    </button>
    """
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  defp icon_path("hero-home"),
    do: "M3.5 10.7 12 3.8l8.5 6.9M5.9 9.4V19a1.4 1.4 0 0 0 1.4 1.4h9.4A1.4 1.4 0 0 0 18.1 19V9.4"

  defp icon_path("hero-calendar-days"),
    do:
      "M3.4 8h17.2M8 3.8v3.6m8-3.6v3.6M5.5 5.5h13a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2h-13a2 2 0 0 1-2-2v-11a2 2 0 0 1 2-2Z"

  defp icon_path("hero-chart-bar"), do: "M4.5 20V13m5 7V6.5m5 13.5v-5m5 5V9.5"

  defp icon_path("hero-list-bullet"),
    do: "M8 6.5h12M8 12h12M8 17.5h12M4 6.5h.01M4 12h.01M4 17.5h.01"

  defp icon_path("hero-cog-6-tooth"),
    do:
      "M12 8.5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7Zm0-5 1 2.2 2.3.6 2-1.2 1.6 1.6-1.2 2 .6 2.3 2.2 1v2.2l-2.2 1-.6 2.3 1.2 2-1.6 1.6-2-1.2-2.3.6-1 2.2H11l-1-2.2-2.3-.6-2 1.2-1.6-1.6 1.2-2-.6-2.3-2.2-1v-2.2l2.2-1 .6-2.3-1.2-2 1.6-1.6 2 1.2 2.3-.6 1-2.2Z"

  defp icon_path("hero-play"), do: "M8 5.5 19 12 8 18.5Z"
  defp icon_path("hero-plus"), do: "M12 5v14M5 12h14"
  defp icon_path("hero-minus"), do: "M5 12h14"
  defp icon_path("hero-check"), do: "m5 12.5 4.5 4.5L19 7"
  defp icon_path("hero-x-mark"), do: "M6 6l12 12M18 6 6 18"
  defp icon_path("hero-trash"), do: "M5 7h14M9 7V4h6v3m2 0-.8 13H7.8L7 7m3 4v5m4-5v5"

  defp icon_path("hero-user-circle"),
    do:
      "M12 3.5a8.5 8.5 0 1 0 0 17 8.5 8.5 0 0 0 0-17Zm0 4a2.7 2.7 0 1 0 0 5.4 2.7 2.7 0 0 0 0-5.4Zm-5 10.8a5.5 5.5 0 0 1 10 0"

  defp icon_path("hero-arrow-right-start-on-rectangle"), do: "M14 5H6v14h8m-3-7h10m-4-4 4 4-4 4"

  defp icon_path("hero-magnifying-glass"),
    do: "M10.5 4a6.5 6.5 0 1 0 0 13 6.5 6.5 0 0 0 0-13Zm5 11.5L21 21"

  defp icon_path("hero-dumbbell"), do: "M3.5 10v4m3-6v8m11-8v8m3-6v4M6.5 12h11"
  defp icon_path("hero-arrow-left"), do: "M19 12H5m6-6-6 6 6 6"
  defp icon_path("hero-chevron-right"), do: "m9 5 7 7-7 7"
  defp icon_path("hero-chevron-left"), do: "m15 5-7 7 7 7"
  defp icon_path("hero-chevron-up"), do: "m5 15 7-7 7 7"
  defp icon_path("hero-chevron-down"), do: "m5 9 7 7 7-7"
  defp icon_path("hero-clock"), do: "M12 3.5a8.5 8.5 0 1 0 0 17 8.5 8.5 0 0 0 0-17Zm0 4v5l3 2"

  defp icon_path("hero-target"),
    do:
      "M12 3.5a8.5 8.5 0 1 0 0 17 8.5 8.5 0 0 0 0-17Zm0 4a4.5 4.5 0 1 0 0 9 4.5 4.5 0 0 0 0-9Zm0 3.2a1.3 1.3 0 1 0 0 2.6 1.3 1.3 0 0 0 0-2.6Z"

  defp icon_path("hero-arrow-up"), do: "M12 19V5m-6 6 6-6 6 6"
  defp icon_path("hero-arrow-down"), do: "M12 5v14m-6-6 6 6 6-6"

  defp icon_path("hero-check-circle"),
    do: "M12 3.5a8.5 8.5 0 1 0 0 17 8.5 8.5 0 0 0 0-17Zm-4 8.7 2.6 2.6 5.5-5.8"

  defp icon_path("hero-moon"), do: "M19.5 14.5A8 8 0 0 1 9.5 4.5a8.5 8.5 0 1 0 10 10Z"

  defp icon_path("hero-shuffle"),
    do:
      "M4 7h3c4 0 5 10 9 10h4m-3-3 3 3-3 3M4 17h3c1.3 0 2.3-1 3.2-2.5M14 9.5C14.9 8 15.8 7 17 7h3m-3-3 3 3-3 3"

  defp icon_path("hero-information-circle"),
    do: "M12 3.5a8.5 8.5 0 1 0 0 17 8.5 8.5 0 0 0 0-17Zm0 7.5v5m0-8.5h.01"

  defp icon_path("hero-pause"), do: "M9 6v12m6-12v12"
  defp icon_path("hero-arrows-pointing-in"), do: "M9 3v6H3m12-6v6h6M9 21v-6H3m12 6v-6h6"
  defp icon_path("hero-arrows-pointing-out"), do: "M3 9V3h6m12 6V3h-6M3 15v6h6m12-6v6h-6"

  defp icon_path("hero-sparkles"),
    do:
      "m8 3 1.2 3.8L13 8l-3.8 1.2L8 13l-1.2-3.8L3 8l3.8-1.2L8 3Zm8 9 1 2.8 3 1.2-3 1.2L16 20l-1-2.8-3-1.2 3-1.2L16 12Z"

  defp icon_path("hero-trophy"),
    do: "M8 4h8v5a4 4 0 0 1-8 0V4Zm0 2H5v2a3 3 0 0 0 3 3m8-5h3v2a3 3 0 0 1-3 3m-4 2v4m-4 3h8"

  defp icon_path("hero-scale"), do: "M12 4v16M5 6h14M7 6l-3 7h6L7 6Zm10 0-3 7h6l-3-7ZM8 20h8"

  defp icon_path("hero-arrow-path"),
    do: "M19 7v5h-5M5 17v-5h5m8.2-3A7 7 0 0 0 6.5 6.5L5 8m.8 7A7 7 0 0 0 17.5 17.5L19 16"

  defp icon_path("hero-globe-alt"),
    do:
      "M12 3.5a8.5 8.5 0 1 0 0 17 8.5 8.5 0 0 0 0-17Zm0 0c2.2 2.4 3.3 5.2 3.3 8.5S14.2 18.1 12 20.5C9.8 18.1 8.7 15.3 8.7 12S9.8 5.9 12 3.5ZM4 12h16"

  defp icon_path("hero-bolt"), do: "m13.5 2.8-7 10h5l-1 8.4 7-11h-5l1-7.4Z"

  defp icon_path("hero-fire"),
    do:
      "M12 21c4 0 7-2.8 7-6.7 0-4.5-4-6.3-3-11.3-3 1-5 3.8-5 6.4 0 1.2-.6 2-1.5 2-1 0-1.5-.8-1.5-2.2-1.3 1.5-2 3.3-2 5.1C5 18.2 8 21 12 21Z"

  defp icon_path(_), do: "M12 3.5a8.5 8.5 0 1 0 0 17 8.5 8.5 0 0 0 0-17Z"
end
