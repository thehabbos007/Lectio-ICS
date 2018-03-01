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
    
    found = body
      |> Floki.find(".s2bgbox")

    extra = found 
      |> Floki.find(".s2skemabrikcontent")
      |> Enum.map(fn x -> elem(x, 2) end)

    [found
      |> Floki.attribute("data-additionalinfo"),

    extra]
    |> Enum.zip
    |> Enum.map(fn {k, v} -> {k, v |> Floki.text} end)

  end

  defp web_string(sch_id, stu_id, week) do
    current_year = Calendar.DateTime.now_utc 
      |> Calendar.Date.week_number
      |> elem(0)

    formatted_week = week <> Integer.to_string(current_year)

    "https://www.lectio.dk/lectio/#{sch_id}/SkemaNy.aspx?type=elev&elevid=#{stu_id}&week=#{formatted_week}"
  end

  def exec(weeks) do
    Enum.map(weeks, fn days -> 
      Enum.map(days, fn lesson -> 
        create_array(lesson)
        |> Enum.reduce(%{}, fn m, acc ->
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
    {lesson, text} = lines

    lesson = String.split(lesson, "\n")

    [ %{"meta" => text} | (for line <- lesson, do: filter(line))]
      |> IO.inspect

  end

  def split_lines(lines) do
    String.split(lines, "\n")
  end

  def filter(line) do
    format = Regex.match?(~r/^([0]?[1-9]|[1|2][0-9]|[3][0|1])[\/]([0]?[1-9]|[1][0-2])[-]([0-9]{4}|[0-9]{2}).*$/, line)
    cond do
      line == "Ændret!" -> %{"status" => "CHANGED"}
      line == "Aflyst!" -> %{"status" => "CANCELLED"}
      format -> format_time(line)
      True -> %{"desc" => line}
     end
  end

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

end