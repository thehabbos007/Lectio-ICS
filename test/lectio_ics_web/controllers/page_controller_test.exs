defmodule LectioIcsWeb.PageControllerTest do
  use LectioIcsWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Hello"
  end

  def within_interval(weeks) when weeks >= 1 and weeks <= 25, do: weeks
  def within_interval(weeks), do:  3

  test "Interval week 30" do
    assert within_interval(30) == 3
  end

  test "Interval week 1" do
    assert within_interval(1) == 1
  end

  test "Interval week -45" do
    assert within_interval(-45) == 3
  end

end
