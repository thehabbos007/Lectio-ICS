defmodule Test do
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

  def filter(line) do
    format = Regex.match?(~r/^([0]?[1-9]|[1|2][0-9]|[3][0|1])[\/]([0]?[1-9]|[1][0-2])[-]([0-9]{4}|[0-9]{2}).*$/, line)
    cond do
      line == "Ændret!" -> %{status: "CHANGED"}
      line == "Aflyst!" -> %{status: "CANCELLED"}
      format -> format_time(line)
      True -> %{"desc": line}
     end
  end
  
end



info = "Ændret!
27/2-2018 08:15 til 09:15
Hold: 3b1 L MA
Lærer: Albena I Nielsen (ain)
Lokale: K.027

Øvrigt indhold:
- I timen [...]"
#info

parsed_1 = String.split(info, "\r\n")
|> IO.inspect
for item <- parsed_1 do
  item
  |> Test.filter
  |> IO.inspect
end
