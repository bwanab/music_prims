defmodule Chord do
  @behaviour Sonority

  @type t :: %__MODULE__{
    chord: ChordPrims.chord(),
    notes: [Note],
    duration: float()
  }

  defstruct [:chord, :notes, :duration]

  @spec new([Note], float()) :: t
  def new(notes, duration) when is_list(notes) do
    %__MODULE__{chord: nil, notes: notes, duration: duration}
  end

  @spec new(ChordPrims.chord(), float()) :: t
  def new(chord, duration) do
    %__MODULE__{chord: chord, notes: nil, duration: duration}
  end

  @impl Sonority
  def duration(rest) do
    rest.duration
  end

  @impl Sonority
  def type() do :chord end

end
