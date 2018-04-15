defmodule LectioIcsWeb.PageController do
  use LectioIcsWeb, :controller

  alias LectioIcs.Helper
  alias LectioIcs.Formatter

  # Denne controller viser indtastningssiden
  def index(conn, _params) do
    render conn, "index.html"
  end

  # Denne controller er en del af APIet der kører gennem hele 
  # scraper/formatteringskoden
  def lectio(conn, %{"school_id" => school_id, "student_id" => student_id, "weeks" => weeks}) do
    # det sikres, at alle de givne værdier er heltal, samt inden for 1 <= weeks <= 25
    with {we, ""} <- Integer.parse(weeks),
         {sc, ""} <- Integer.parse(school_id),
         {st, ""} <- Integer.parse(student_id)
    do 
      # Hvis alt stemmer, køres denne funktion 
      render_all(conn, sc, st, within_interval(we))
    else
      # Ellers opstår en fejl
      _ -> text conn, "De givne parametre er forkerte"
    end

  end

  defp render_all(conn, school_id, student_id, weeks) do
    # Lectio scrapes for skemainformation, læs mere i Helper modulet
    calendar = Helper.get(school_id, student_id, weeks)

    # Resultaterne fra før sættes igennem en række funktioner
    # heriblandt bliver skemabrikkerne omdannet til ICS tekstformat
    res = calendar
      |> Helper.exec
      |> List.flatten
      |> LectioIcs.Formatter.format
      # Her indsættes en tidszone, samt metadata for ICS kaldeneren, hvilket
      # eksempelvis Google Calendar gør brug af
      |> String.replace("VERSION:2.0\n", "VERSION:2.0\nMETHOD:PUBLISH\nX-PUBLISHED-TTL:PT15M\nX-WR-CALNAME:Lectio skema\nX-WR-TIMEZONE:Europe/Copenhagen\n")
    
    # Det resulterende ICS text vises til brugere, hvilket i andre
    # ord vises som en kaldender i form af et link på 
    # diverse kalender services.
    text conn, res
  end

  def within_interval(weeks) when weeks >= 1 and weeks <= 25, do: weeks
  def within_interval(weeks), do:  3


end
