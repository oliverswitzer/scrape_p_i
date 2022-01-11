defmodule ScrapePIWeb.ScrapedApiController do
  use ScrapePIWeb, :controller

  def show(conn, _params) do
    conn |> json(%{})
  end
end
