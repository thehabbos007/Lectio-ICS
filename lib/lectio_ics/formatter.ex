defmodule LectioIcs.Formatter do

  def format(map) do 

    events = Enum.map(map, fn x -> 
      
      summary = cond do
        Map.has_key?(x, :curr)  -> x.team <> " - " <> x.teacher <> " - " <> x.curr 
        Map.has_key?(x, :team) -> x.team <> " - " <> x.teacher
        True -> x.teacher
      end

      room = cond do
        Map.has_key?(x, :room) -> x.room
        True -> ""
      end

      cond do
        Map.has_key?(x, :other) and Map.has_key?(x, :status)  -> %ICalendar.Event{
          summary:  "📝 - " <> summary,
          dtstart: x.start_time,
          dtend:   x.end_time,
          description: x.other,
          location: room,
          status: x.status
          }

        Map.has_key?(x, :other) -> %ICalendar.Event{
          summary:  "📝 - " <> summary,
          dtstart: x.start_time,
          dtend:   x.end_time,
          description: x.other,
          location: room
          }

        Map.has_key?(x, :status)  -> %ICalendar.Event{
          summary: summary,
          dtstart: x.start_time,
          dtend:   x.end_time,
          location: room,
          status: x.status
          }

        True -> %ICalendar.Event{
          summary: summary,
          dtstart: x.start_time,
          dtend:   x.end_time,
          location: room
          } 
      end

    end )

    ics = %ICalendar{ events: events } |> ICalendar.to_ics

  
  end

  def formatT(map) do 

    events = Enum.map(map, fn x -> 
      
      summary = cond do
        Map.has_key?(x, :curr)  -> x.team <> " - " <> x.teacher <> " - " <> x.curr 
        Map.has_key?(x, :team) -> x.team <> " - " <> x.teacher
        True -> x.teacher
      end

      room = cond do
        Map.has_key?(x, :room) -> x.room
        True -> ""
      end

      cond do
        Map.has_key?(x, :other) and Map.has_key?(x, :status)  -> %ICalendar.Event{
          summary:  "📝 - " <> summary,
          dtstart: x.start_time,
          dtend:   x.end_time,
          description: x.other,
          location: room,
          status: x.status
          }

        Map.has_key?(x, :other) -> %ICalendar.Event{
          summary:  "📝 - " <> summary,
          dtstart: x.start_time,
          dtend:   x.end_time,
          description: x.other,
          location: room
          }

        Map.has_key?(x, :status)  -> %ICalendar.Event{
          summary: summary,
          dtstart: x.start_time,
          dtend:   x.end_time,
          location: room,
          status: x.status
          }

        True -> %ICalendar.Event{
          summary: summary,
          dtstart: x.start_time,
          dtend:   x.end_time,
          location: room
          } 
      end

    end )

    ics = %ICalendar{ events: events } |> ICalendar.to_ics

  
  end


end