defmodule TamagymWeb.ErrorHTML do
  @moduledoc "HTML error pages for browser requests."
  use TamagymWeb, :html

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
