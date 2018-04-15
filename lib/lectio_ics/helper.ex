defmodule LectioIcs.Helper do

  # Dette modul er mere involveret, siden det indeholder 
  # hjemmeside scraping, datafiltrering og aggregation

  # Denne funktion, get, tager alt elevens information 
  # og skaber en liste af links der skal scrapes
  # Derefter udtrækkes skemabrikker for hver uge
  # som kort/lange brikoplysninger
  def get(sch_id, stu_id, weeks) do
    # Lectios dato i skemalinket består af ugenummeret + det nuværende år
    current_week = Calendar.DateTime.now_utc 
      |> Calendar.Date.week_number
      |> elem(1)
    # datoen skal være paddet, så hvis det er uge 2, bliver det til
    # 02
    week_range = current_week..current_week+weeks-1
                  |> Enum.map(fn(x) -> Integer.to_string(x)
                    |> String.pad_leading(2,"0")
                  end)
    # for hver datoværdi, findes et tilsvarende 
    # lectio skemalink.
    combined = Enum.map(week_range, fn(x) -> 
      web_string(sch_id, stu_id, x)
      |> title_list
    end)
    combined
  end

  defp web_string(sch_id, stu_id, week) do
    current_year = Calendar.DateTime.now_utc 
      |> Calendar.Date.week_number
      |> elem(0)

    formatted_week = week <> Integer.to_string(current_year)

    # Ugelinket sættes sammen med skolens id og elevens, for at oprette
    # GET requests for at scrape
    "https://www.lectio.dk/lectio/#{sch_id}/SkemaNy.aspx?type=elev&elevid=#{stu_id}&week=#{formatted_week}"
  end

  # Efter listen af links er oprettet, GET anmodes linkene
  defp title_list(url) do
    # HTTPoison biblioteket anvendes for at foretage 
    # HTTP handlinger. Samt Floki for at filtrere data
    HTTPoison.start
    %HTTPoison.Response{body: body} = HTTPoison.get! url, [], [ ssl: [{:versions, [:'tlsv1.2']}] ]
    
    # Der søges efter .s2bgbox elementer, hvilekt indeholder den fulde 
    # "data-additionalinfo" med skemaindhold
    found = body
      |> Floki.find(".s2bgbox")

    # Der søges efter .s2skemabrikcontent elementer, som indeholder
    # en kort beskrivelse af skemabrikkens indhold
    extra = found 
      |> Floki.find(".s2skemabrikcontent")
      |> Enum.map(fn x -> elem(x, 2) end)


    # En liste [found, extra] kombineres, hvorved 
    # "data-additionalinfo" og derved det fulde skemaindhold
    # findes
    [found
      |> Floki.attribute("data-additionalinfo"),
     extra]
    # Listen med de to værdier omdannes som ved følgende
    # [[1, 2, 3, 4, 5], [:a, :b, :c]] -> [{1, :a}, {2, :b}, {3, :c}]
    # {1, :a} er en tupel, som er ligesom en liste
    # der har en fast størrelse
    |> Enum.zip
    # For "extra", altså den korte version af skemabrikken
    # findes indholdet ved seperatoren " ", mellumrum.
    |> Enum.map(fn {k, v} -> {k, v |> Floki.text(sep: " ")} end)

  end


  # Denen funktion skal køres på resultatet af get/3 funktionen ovenfra
  # Den gennemgår alle skemabrikker for alle dage, og 
  # omdanner dem til map-strukture, á la %{meta: "", desc: "", ..}
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

  # Denne funktion filtrerer alle linjerne i skemabrikkernes indhold
  # og bruger "pattern matching" til at bestemme indhold og
  # nøgle i map struktur
  def create_array(lines) do  
    {lesson, text} = lines

    lesson = String.split(lesson, "\n")

    # Filter funktionen kører på alle skemabrikkens linjer
    [ %{:meta => text} | (for line <- lesson, do: filter(line))]

  end

  def split_lines(lines) do
    String.split(lines, "\n")
  end

  # Denne funktion tjekker linjens værdi, for at opdele diverse 
  # muligheder i forskellige resultater.
  def filter(line) do
    # 
    format = Regex.match?(~r/^([0]?[1-9]|[1|2][0-9]|[3][0|1])[\/]([0]?[1-9]|[1][0-2])[-]([0-9]{4}|[0-9]{2}).*$/, line)
    cond do
      # den nuværende linje kan være nogle  specifikke værdier
      line == "Ændret!" -> %{:status => "CHANGED"}
      line == "Aflyst!" -> %{:status => "CANCELLED"}
      # For andet end skemabrikkens status udføres forskellige 
      # resultater
      format -> format_time(line)

      # Hvis ingen ovenstående betingelser opfyldes, 
      # er den nuværende linje skemabrikkens beskrivelse
      True -> %{:desc => line}
     end
  end

  def format_time(line) do
    # Denne funktion formattere skemabrikkens tider til
    # formattet: {{2015, 12, 24}, {8, 45, 00}}
    # som ICalendar biblioteket anvender.

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
      :start_time => {{Enum.at(date, 2), Enum.at(date, 1), Enum.at(date, 0)}, {Enum.at(start_time, 0), Enum.at(start_time, 1), 00}},
      :end_time => {{Enum.at(date, 2), Enum.at(date, 1), Enum.at(date, 0)}, {Enum.at(end_time, 0), Enum.at(end_time, 1), 00}}
    }

    formatted   
  end

end
