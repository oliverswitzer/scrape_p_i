defmodule ScrapePI.Scraper do
  use Hound.Helpers

  def execute(instructions) do
    Hound.start_session(browser: "chrome_headless", user_agent: :chrome_desktop)

    Enum.reduce(instructions, %{}, fn ins, acc ->
      case ins.command do
        "visit" ->
          navigate_to(ins.value)
          acc

        "scrape" ->
          fetch_from_selector_and_strategy(ins.mapping)
          # should look like 
          # %{flags => [
          #   %{state_name: "Alabama", flag_url: "/wiki/Alabama"} 
          #   ...
          # ]}

          # scraped_results = for value <- values, do: %{data_name => value}
      end
    end)

    # :timer.sleep(1000)

    # count =
    #   find_element(:id, "currocc")
    #   |> visible_text()
    #   |> String.to_integer()

    # Hound.end_session(self())

    # count
  end

  defp fetch_from_selector_and_strategy(%{
         "name" => field_name,
         "selector" => selector,
         "get" => ["attribute", attribute_name] 
       }) do
    attribute_value(element, attribute_name)

    for value <- values, do: %{field_name => value}
  end

  defp fetch_from_selector_and_strategy(%{
         "name" => field_name,
         "selector" => selector,
         "get" => "text" 
       }) do
    # needs to return [
    #   %{}
    # ] 
    elements = find_all_elements(selector, :css)

    elements |> Enum.map(&visible_text/1)

    for value <- values, do: %{field_name => value}
  end

    defp fetch_from_selector_and_strategy(%{
         "name" => field_name,
         "selector" => selector,
         "for_each" => child_mapping 
       }) do
          fetch_from_selector_and_strategy(child_mapping)

        _ ->
          IO.puts("yolo")
      end

    for value <- values, do: %{field_name => value}
  end

end
