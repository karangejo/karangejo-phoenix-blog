defmodule KarangejoBlogWeb.PageController do
  use KarangejoBlogWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
