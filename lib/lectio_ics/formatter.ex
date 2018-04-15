defmodule LectioIcs.Formatter do
  # dette modul består kun af en funktion
  # hvis primære funktion er, at formattere 
  # enkelte "skemabrikker" som en
  # [%{meta: "", desc: "x", start_time: {xxxx,xx,xx}, end_time: {xxxx,xx,xx}}, ..]
  # struktur

  def format(map) do 
    # map variablen er reelt set en liste af maps (en map er en datastruktur á la %{z: "x"})
    events = Enum.map(map, fn x -> 
      # Hver enkel datastruktyr gennemgås. Enum.map svarer ti let for loop
      # Alle skemaindhold sammensættes med et linjeskift
      description = Enum.join(x.desc, "\n")

      # Et bibliotek, "ICalendar" anvendes til at omdanne maps til
      # tekst i ICS format

      # Som led i omdannelsen, tjekkes der antal linjer i Lectio beskrivelsen
      # for at angive et gæt til hvornår Noter eller Lektier er på skemaet
      desclen = length(x.desc)
      %ICalendar.Event{
        # Hvis der eksistere en note/lektier tilføjes et symbol for at fremhæve
        # skemabrikken i kalenderen.
        summary: (if desclen > 5, do: "* - " <> x.meta, else: x.meta),
        dtstart: x.start_time,
        dtend:   x.end_time,
        description: description
      } 
      
    end )

    # Listen som fås ved "for loopet", Enum.map, omdannes fra n-dimensioner
    # til 1-dimension
    events = List.flatten events

    # Alle skemabrikkerne er nu en del af "events" listen, og derved
    # kan disse enkelte elementer, som er %ICalendar.Event{} datastrukture
    # sættes sammen til en samlet kaldender i stedet for individuelle skemabrikker
    %ICalendar{ events: events } 
    |> ICalendar.to_ics

  end

end
