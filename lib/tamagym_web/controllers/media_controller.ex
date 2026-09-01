defmodule TamagymWeb.MediaController do
  use TamagymWeb, :controller

  @image_name ~r/\A[a-zA-Z0-9_.-]+\.(?:jpg|jpeg|png|webp)\z/
  @gif_name ~r/\A[a-zA-Z0-9_.-]+\.gif\z/

  def image(conn, %{"filename" => filename}), do: serve(conn, "img", filename, @image_name)
  def gif(conn, %{"filename" => filename}), do: serve(conn, "gif", filename, @gif_name)

  defp serve(conn, directory, filename, allowed_name) do
    with true <- Regex.match?(allowed_name, filename),
         path <- Path.join([media_dir(), directory, filename]),
         true <- File.regular?(path) do
      conn
      |> put_resp_content_type(MIME.from_path(filename))
      |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
      |> send_file(200, path)
    else
      _ ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Media not found"})
    end
  end

  defp media_dir do
    Application.fetch_env!(:tamagym, :media_dir)
  end
end
