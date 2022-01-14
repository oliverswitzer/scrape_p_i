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
            "name" => "flags",
            "selector" => ".divcol li",
            "for_each" => [
              %{
                "name" => "flag_url",
                "selector" => ".flagicon > img",
                "get" => ["attribute", "src"]
              },
              %{
                "name" => "state_name",
                "selector" => "a",
                "get" => "text"
              }
            ]
          }
        }
      ]

      instructions = [
        ["visit", "https://example.com"],
        [
          "find_first",
          %{
            # Not providing name: key here which means this is a transient
            # field... e.g. I don't want this to show in the API response so I
            # don't give it a name. Solely meant to get a parent container first
            # and then fetch within it.
            "selector" => ".divcol li",
            "map" => [
                "find_all",
                %{
                  "name" => "flag_url",
                  "selector" => ".flagicon > img",
                  "get" => ["attribute", "src"]
                }
              ]
            ]
          }
        ],
        [
          "find_all",
          %{
            "name" => "state_flags",
            "selector" => ".flag",
            "map" =>
              "get_text"
              | ["get_attribute", "<attribute_name>"]
              | [
                  # Can either pass an array after find_first to indicate that
                  # you want to find multiple elements within the element your
                  # currently mapping over, or just pass one %{} specifying
                  # name, selector and map if you only want one nested field.

                  # Maybe as a first pass it just always accepts an array and
                  # you can just opt to only pass one item to it.
                  "find_first",
                  [
                    %{
                      "name" => "flag_url",
                      # This query is run on an element that matched ".flag" from the 
                      # find_all query its nested in
                      "selector" => ".flagicon > img",
                      "map" => ["get_attribute", "src"]
                    },
                    %{
                      "name" => "name",
                      "selector" => "a",
                      "map" => "get_text"
                    },
                    %{
                      "name" => "cities",
                      "selector" => ".cities",
                      "map" => [
                        "find_all", 
                        %{
                          "selector" => ".city"
                          "map" => "get_text"
                          # Note that we dont provide the `name: <field_name>`
                          # key here, since the
                          # API response we want back would have an unecessary
                          # intermediate key if we did... ie if we provided a
                          # redundant `name: "city"` key, it would look like:

                          # {
                          #   state_flags: [
                          #     {
                          #       name: "New York",
                          #       flag_url: "https://example.com/flag/some_name"
                          #       cities: {
                          #         {city: "New York"},
                          #         {city: "Albany"},
                          #         ...
                          #       }
                          #     },
                          #     ...
                          #
                          #   ]
                          # }
                          #
                          # VS not providing name: "city" key...
                          # {
                          #   state_flags: [
                          #     {
                          #       name: "New York",
                          #       flag_url: "https://example.com/flag/some_name"
                          #       cities: {
                          #         "New York"  
                          #         "Albany",
                          #         ...
                          #       }
                          #     }
                          #   ]
                          # }
                        }
                      ]
                    }
                  ]
                ]
          }
        ],
        # [
        #   "find_first",
        #   %{
        #     "selector" => ".some_counter",
        #     "do" => "click" | "submit" | ["fill_input", "<value>"] | "mouse_over"
        #   }
        # ]
      ]

      expected_res = %{
        data: [
            [
              {flag_url: "/url"},
              {flag_url: "/url"}
            ],
            {
              state_flags: [
                {
                  name: "New York",
                  flag_url: "https://example.com/flag/some_name"
                  cities: {
                    "New York"  
                    "Albany",
                    ...
                  }
                }
              ]
            }
          }
        ]
      }

      # [
      #   [command, value]
      # ]

      # command = url.t() | find_all.t() | find_first.t()

      # find_all.t() = [
      #   "find_all",
      #   %{do: command.t()} | %{ map: query.t() }
      # ]

      # find_first = [
      #   "find_all",
      #   %{do: do_command.t()} | %{ map: query.t() }
      # ]

      # instructions = [
      #   %{
      #     command: "visit",
      #     value: "https://en.wikipedia.org/wiki/U.S._state"
      #   },
      #   %{
      #     command: "fetch_all",
      #     value: 
      #   }
      # ]

      [instructions: instructions]
    end

    test "executes the instructions", %{instructions: instructions} = context do
      result = Scraper.execute(instructions)

      Routes.scraped_api_path(Endpoint, :show, "flags")

      conn = get(build_conn(), "/api/v1/flags")
      res = conn.resp_body |> Jason.decode!()

      flags = result["data"]
      # %{
      #   "data" => %{
      #     "flags" => [
      #       %{
      #         "state_name" => "Alabama",
      #         "flag_url" => "https://en.wikipedia.org/wiki/U.S._state/wiki/Alabama"
      #       },
      #       %{
      #         "state_name" => "Alaska",
      #         "flag_url" => "https://en.wikipedia.org/wiki/U.S._state/wiki/Alaska"
      #       },
      #       %{
      #         "state_name" => "Arizona",
      #         "flag_url" => "https://en.wikipedia.org/wiki/U.S._state/wiki/Arizona"
      #       }
      #     ]
      #   }
      # }

      assert flags
      assert flags |> length == 50

      first_three_parsed = Enum.slice(flags, 0..3)

      assert first_three_parsed = [
               %{
                 "state_name" => "Alabama",
                 "flag_url" => "https://en.wikipedia.org/wiki/U.S._state/wiki/Alabama"
               },
               %{
                 "state_name" => "Alaska",
                 "flag_url" => "https://en.wikipedia.org/wiki/U.S._state/wiki/Alaska"
               },
               %{
                 "state_name" => "Arizona",
                 "flag_url" => "https://en.wikipedia.org/wiki/U.S._state/wiki/Arizona"
               }
             ]
    end
  end
end
