defmodule KarangejoBlogWeb.LayoutView do
  use KarangejoBlogWeb, :view

  crab_svg = File.read!("priv/static/images/crab.svg")

  def crab_svg do
    unquote(crab_svg)
  end

end
