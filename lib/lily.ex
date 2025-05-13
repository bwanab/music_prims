

defmodule Lily do

  @preamble "\\version \"2.24.4\" \n"
  @doc """
  Render a list of sonorities to a Lilypond string.
  """
  @spec show([Sonority.t()]) :: String.t()
  def show(sonorities) when is_list(sonorities) do
    Enum.map(sonorities, fn s -> Sonority.show(s) end) |> Enum.join(" ")
  end
  @doc """
  Render a list of sonorities to a Lilypond string.
  """
  @spec render([Sonority.t()]) :: String.t()
  def render(sonorities) when is_list(sonorities) do
    s = Lily.show(sonorities)
    @preamble <> "{\n #{s} \n}"
  end

  @spec render(Sonority.t()) :: String.t()
  def render(sonority) do
    @preamble <> "{
      #{Sonority.show(sonority)}
    }"
  end


end
