defmodule TamagymWeb.Layouts do
  @moduledoc "Root and application layouts for tamagym."
  use TamagymWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <main class="lv-page">
      {render_slot(@inner_block)}
    </main>
    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true

  def flash_group(assigns) do
    ~H"""
    <div id="flash-group" aria-live="polite">
      <div
        :if={message = Phoenix.Flash.get(@flash, :info)}
        class="lv-flash"
        phx-click={JS.push("lv:clear-flash", value: %{kind: "info"})}
      >
        {message}
      </div>
      <div
        :if={message = Phoenix.Flash.get(@flash, :error)}
        class="lv-flash error"
        phx-click={JS.push("lv:clear-flash", value: %{kind: "error"})}
      >
        {message}
      </div>
      <div
        id="client-error"
        class="lv-flash error phx-client-error"
        hidden
        phx-disconnected={JS.show()}
        phx-connected={JS.hide()}
      >
        Connection lost — reconnecting…
      </div>
    </div>
    """
  end
end
