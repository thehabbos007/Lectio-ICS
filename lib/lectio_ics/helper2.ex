defmodule LectioIcs.HelperT do

  def get(sch_id, stu_id, weeks) do

    current_week = Calendar.DateTime.now_utc 
      |> Calendar.Date.week_number
      |> elem(1)

    week_range = current_week..current_week+weeks-1
                  |> Enum.map(fn(x) -> Integer.to_string(x)
                    |> String.pad_leading(2,"0")
                  end)

    combined = Enum.map(week_range, fn(x) -> 
      web_string(sch_id, stu_id, x)
      |> title_list
    end)


    combined

  end

  defp title_list(url) do
    HTTPoison.start
    %HTTPoison.Response{body: body} = HTTPoison.get! url, [], [ ssl: [{:versions, [:'tlsv1.2']}] ]
    body
      |> Floki.find(".s2bgbox")
      |> Floki.attribute("data-additionalinfo")

  end

  defp web_string(sch_id, stu_id, week) do
    current_year = Calendar.DateTime.now_utc 
      |> Calendar.Date.week_number
      |> elem(0)

    formatted_week = week <> Integer.to_string(current_year)

    "https://www.lectio.dk/lectio/#{sch_id}/SkemaNy.aspx?type=elev&elevid=#{stu_id}&week=#{formatted_week}"
  end

  def exec(weeks) do
    Enum.map(weeks, fn x -> 
      Enum.map(x, fn y -> 
        create_array(y) 
        |> IO.inspect |>Enum.reduce(%{}, fn m, acc ->
          Map.merge(acc, m, fn
            _k, v1, v2 when is_list(v1) ->
              :lists.reverse([v2 | :lists.reverse(v1)])
            _k, v1, v2 -> [v1, v2]
          end)
        end)
      end)
    end)
  end

  def create_array(lines) do  
    lines
      |> split_lines
      |> Enum.map(fn x -> run_command(x) end)
      #|> event_state
  end

  def split_lines(lines) do
    String.split(lines, "\n")
  end

  def run_command(command) do
    do_run_command String.split(command, ":"), command

    case String.split(command, ":") do
      [x, y] -> do_run_command([x, y], command)
      [x]    -> get_resulting_data(x)
      x      -> do_run_command(x, command)

    end
  end


  defp do_run_command([a, b, c], line) do
    cond do
      Regex.match?(~r/^([0]?[1-9]|[1|2][0-9]|[3][0|1])[\/]([0]?[1-9]|[1][0-2])[-]([0-9]{4}|[0-9]{2}).*$/, line) ->
        format_time(line)
      
      True -> Map.put(%{}, "other", line) 
        
    end
  end

  defp do_run_command(["Note", value], line) do
    Map.put(%{}, "note", value)
  end

  defp do_run_command(["- " <> data], line) do
    Map.put(%{}, "note", data)
  end

  defp do_run_command([item, value], line) when item === "Lektier" or item === "Note" do
    Map.put(%{}, item, " ")
  end

  defp do_run_command([item, value], line) do
    Map.put(%{}, item, value)
  end

  defp do_run_command(["Ændret!"], line), do: Map.put(%{}, "status", "Ændret!") 
  defp do_run_command(["Aflyst!"], line), do: Map.put(%{}, "status", "Aflyst!") 
  defp do_run_command([x], line) do 
    Map.put(%{}, "status", x) 
  end


  #defp say(thing, count) when count < 100, do: String.duplicate(thing, count)
  #defp say(thing, _count), do: say(thing, 99) <> " etc"

  def format_time(line) do
    #{{2015, 12, 24}, {8, 45, 00}}

    time_string = String.split(line, " ")
    IO.inspect line

    date = time_string 
      |> Enum.at(0)
      |> (&Regex.scan(~r/\d{1,4}/, &1)).()
      |> List.flatten
      |> Enum.map(fn(x) -> String.to_integer(x) end)


    start_time = Enum.at(time_string, 1) 
      |> String.split(":")
      |> Enum.map(fn(x) -> String.to_integer(x) end)

    end_time = Enum.at(time_string, 3)
      |> String.split(":")
      |> Enum.map(fn(x) -> String.to_integer(x) end)

    formatted = %{
      "start_time" => {{Enum.at(date, 2), Enum.at(date, 1), Enum.at(date, 0)}, {Enum.at(start_time, 0), Enum.at(start_time, 1), 00}},
      "end_time" => {{Enum.at(date, 2), Enum.at(date, 1), Enum.at(date, 0)}, {Enum.at(end_time, 0), Enum.at(end_time, 1), 00}}
    }

    #IO.inspect date
    #extract_team(rest, formatted) 
    formatted   
  end

  def get_resulting_data(line) when line === "" do
    Map.put(%{}, "other", " ") 
  end

  def get_resulting_data(line) do
    Map.put(%{}, "other", line) 
  end

end