defmodule ScrapePI.ScraperTest do
  use ScrapePIWeb.ConnCase, async: true

  @endpoint ScrapePIWeb.Endpoint

  alias ScrapePI.Scraper
  alias ScrapePIWeb.Endpoint

  describe "given a simple set of instructions" do
    setup do
      instructions = [
        %{
          command: "visit",
          value: "https://en.wikipedia.org/wiki/U.S._state"
        },
        %{
          command: "scrape",
          mapping: %{
            "state" => %{
              "selector" => ".flagicon ~ a",
              "get" => "text"
            }
          }
        }
      ]

      [instructions: instructions]
    end

    test "executes the instructions", %{instructions: instructions} = context do
      Scraper.execute(instructions, namespace: "flags")

      Routes.scraped_api_path(Endpoint, :show, "flags")

      conn = get(build_conn(), "/api/v1/flags")
      res = conn.resp_body |> Jason.parse!()

      first_three_parsed = Enum.slice(res["data"], 0..3)

      assert first_three_parsed = [
               %{"state" => "Alabama"},
               %{"state" => "Alaska"},
               %{"state" => "Arizona"}
             ]
    end
  end
end
