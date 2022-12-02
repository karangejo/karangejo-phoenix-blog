defmodule KarangejoBlogWeb.LayoutView do
  use KarangejoBlogWeb, :view

  crab_svg = File.read!("priv/images/crab.svg")

  def crab_svg do
    unquote(crab_svg)
  end

end
