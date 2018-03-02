defmodule LectioIcsWeb.PageController do
  use LectioIcsWeb, :controller

  alias LectioIcs.Helper
  alias LectioIcs.HelperT
  alias LectioIcs.Formatter

  def index(conn, _params) do
    render conn, "index.html"
  end

  def lectio(conn, %{"school_id" => school_id, "student_id" => student_id, "weeks" => weeks}) do

    with {we, ""} <- Integer.parse(weeks),
         {sc, ""} <- Integer.parse(school_id),
         {st, ""} <- Integer.parse(student_id)
    do 
      render_all(conn, sc, st, we)
    else
      _ -> text conn, "Pls fix de params, m8"
    end

  end

  defp render_all(conn, school_id, student_id, weeks) do

    de = HelperT.get(school_id, student_id, weeks)

    #IO.inspect de
      #|> List.flatten()

    res = de
      |> HelperT.exec
      |> Enum.map(fn x->LectioIcs.FormatterT.format(x) end)
      |> List.flatten
      |> Enum.join("")
      |> String.replace("VERSION:2.0\n", "VERSION:2.0\nMETHOD:PUBLISH\nX-PUBLISHED-TTL:PT15M\nX-WR-CALNAME:Lectio skema\nX-WR-TIMEZONE:Europe/Copenhagen\n")
    
    text conn, res
  end

end
