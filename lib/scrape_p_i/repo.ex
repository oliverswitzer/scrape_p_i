defmodule ScrapePI.Repo do
  use Ecto.Repo,
    otp_app: :scrape_p_i,
    adapter: Ecto.Adapters.Postgres
end
