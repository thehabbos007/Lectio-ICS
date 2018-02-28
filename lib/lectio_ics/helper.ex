defmodule LectioIcs.Helper do

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

  def exec(lines) do
    lines
      |> split_lines
      |> event_state
  end

  def split_lines(lines) do
    String.split(lines, "\n")
  end

  def date_vs_curr(lines) do
    line = List.first(lines)

    res = cond do
      Regex.match?(~r/^([0]?[1-9]|[1|2][0-9]|[3][0|1])[\/]([0]?[1-9]|[1][0-2])[-]([0-9]{4}|[0-9]{2}).*$/, line) -> format_time(lines)
      True -> extract_curr(lines) 
    end

  end

  def date_vs_curr(lines, opts) do
    line = List.first(lines)

    res = cond do
      Regex.match?(~r/^([0]?[1-9]|[1|2][0-9]|[3][0|1])[\/]([0]?[1-9]|[1][0-2])[-]([0-9]{4}|[0-9]{2}).*$/, line) -> format_time(lines, opts)
      True -> extract_curr(lines, opts) 
    end

  end

  def extract_curr(lines) do
    line = List.first(lines)
    [_h | rest] = lines

    format_time(rest, %{curr: line})
  end

  def extract_curr(lines, opts) do
    line = List.first(lines)
    [_h | rest] = lines

    formatted = %{curr: line}

    combined = Map.merge(opts, formatted)

    format_time(rest, combined)
  end


  def format_time(lines) do
    #{{2015, 12, 24}, {8, 45, 00}}
    line = List.first(lines)
    [_h | rest] = lines


    time_string = String.split(line, " ")

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
      start_time: {{Enum.at(date, 2), Enum.at(date, 1), Enum.at(date, 0)}, {Enum.at(start_time, 0), Enum.at(start_time, 1), 00}},
      end_time: {{Enum.at(date, 2), Enum.at(date, 1), Enum.at(date, 0)}, {Enum.at(end_time, 0), Enum.at(end_time, 1), 00}}
    }

    #IO.inspect date
    possible_x(rest, formatted, "Elev")
    #extract_team(rest, formatted)    
  end

  def format_time(lines, opts) do
    #{{2015, 12, 24}, {8, 45, 00}}
    line = List.first(lines)
    [_h | rest] = lines

    time_string = String.split(line, " ")

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
      start_time: {{Enum.at(date, 2), Enum.at(date, 1), Enum.at(date, 0)}, {Enum.at(start_time, 0), Enum.at(start_time, 1), 00}},
      end_time: {{Enum.at(date, 2), Enum.at(date, 1), Enum.at(date, 0)}, {Enum.at(end_time, 0), Enum.at(end_time, 1), 00}}
    }

    combined = Map.merge(opts, formatted)

    possible_x(rest, formatted, "Elev")
    #extract_team(rest, combined)  
    
  end

  def possible_x(lines, opts,x) do
    [line | rest] = lines
    res = cond do
      String.contains?(line, x<>": ") -> extract_team(rest, opts)
      True -> extract_team(lines, opts) 
    end
  end

  def extract_team(lines, opts) do
    line = List.first(lines)
    [_h | rest] = lines

    cond do
      String.contains?(line, "Lære") -> res = teacher_vs_teachers!(lines, opts)

      Trie -> "Hold: " <> team = line
              formatted = %{team: team}
              combined = Map.merge(opts, formatted)
              teacher_vs_teachers(rest, combined)
    end

  end

  def teacher_vs_teachers(lines, opts) do
    line = List.first(lines)
    line_data = Regex.run(~r/\(([^)]+)\)/, line)
    cond do
      line_data != nil -> extract_teacher(lines, opts) 
      line_data == nil -> extract_teachers(lines, opts) 
    end
    
  end

  def teacher_vs_teachers!(lines, opts) do
    line = List.first(lines)
    [_h | rest] = lines

    line_data = Regex.run(~r/\(([^)]+)\)/, line)
    combined = cond do
      line_data != nil -> list = Regex.run(~r/\(([^)]+)\)/, line)
                          formatted = %{teacher: Enum.at(list, 1)}
                          Map.merge(opts, formatted) 

      line_data == nil -> "Lærere: " <> teachers = line
                          teacher_list = String.split(teachers, ",")
                          formatted = %{teacher: Enum.join(teacher_list, " ")}
                          Map.merge(opts, formatted)
    end

    get_resulting_data(rest, combined)
    
  end

  def extract_teacher(lines, opts) do
    line = List.first(lines)
    [_h | rest] = lines

    list = Regex.run(~r/\(([^)]+)\)/, line)

    formatted = %{teacher: Enum.at(list, 1)}

    combined = Map.merge(opts, formatted)

    room_vs_rooms(rest, combined)
    
  end

  def extract_teachers(lines, opts) do
    line = List.first(lines)
    [_h | rest] = lines

    "Lærere: " <> teachers = line

    teacher_list = String.split(teachers, ",")

    formatted = %{teacher: Enum.join(teacher_list, " ")}

    combined = Map.merge(opts, formatted)

    room_vs_rooms(rest, combined)
    
  end

  def room_vs_rooms(lines, opts) do
    line = List.first(lines)

    cond do
      String.contains?(line, "Lokaler") -> extract_rooms(lines, opts) 
      String.contains?(line, "Lokale")  -> extract_room(lines, opts)                 
      True ->  formatted = %{room: "????"}
               combined  = Map.merge(opts, formatted)
               [_h | rest] = lines
               get_resulting_data(rest, combined)

    end

  end

  def extract_room(lines, opts) do
    line = List.first(lines)
    [_h | rest] = lines

    room = Regex.run(~r/[Kk01]\.\d{3}/, line)

    formatted = %{room: List.first(room)}

    combined = Map.merge(opts, formatted)

    get_resulting_data(rest, combined)
  end

  def extract_rooms(lines, opts) do
    line = List.first(lines)
    [_h | rest] = lines

    rooms = Regex.scan(~r/[Kk01]\.\d{3}/, line)

    formatted = %{room: Enum.join(rooms, " ")}

    combined = Map.merge(opts, formatted)

    get_resulting_data(rest, combined)
  end

  def get_resulting_data(lines, opts) do
    
    case lines do
      [_h | rest] -> rest = %{other: Enum.join(rest, "\n")}
                     Map.merge(opts, rest)
      []          -> opts
    end   
  end

  def event_state(lines) do
    line = List.first(lines)
    [_h | rest] = lines

    data = cond do
      line == "Aflyst!"  -> date_vs_curr(rest, %{status: "CANCELLED"})
      line == "Ændret!"  -> date_vs_curr(rest, %{status: "CHANGED"})
      True               -> date_vs_curr(lines)
    end
    
  end


end
