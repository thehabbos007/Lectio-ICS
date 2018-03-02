defmodule LectioIcs.FormatterT do

  def format(map) do 

    events = Enum.map(map, fn x -> 
      description = Enum.join(x.desc, "\n")
      desclen = length(x.desc)
      %ICalendar.Event{
         summary: (if desclen > 5, do: "📝 - " <> x.meta, else: x.meta),
         dtstart: x.start_time,
         dtend:   x.end_time,
         description: description
      } 
      
    end )

    events = List.flatten events
    #|> IO.inspect

    %ICalendar{ events: events } 
    |> ICalendar.to_ics

  
  end



end
