defmodule KarangejoBlogWeb.PostView do
  use KarangejoBlogWeb, :view

  def to_markdown(md) do
    md
    |> Earmark.as_html!()
    |> raw()
  end
end
