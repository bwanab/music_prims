defmodule Chord do

  @type t :: %__MODULE__{
    chord: ChordPrims.chord(),
    notes: [Note],
    duration: float()
  }

  defstruct [:chord, :notes, :duration]

  @spec new([Note.t()], float()) :: Sonority.t()
  def new(notes, duration) when is_list(notes) do
    %__MODULE__{chord: nil, notes: notes, duration: duration}
  end

  @spec new(ChordPrims.chord(), float()) :: Sonority.t()
  def new(chord, duration) do
    %__MODULE__{chord: chord, notes: nil, duration: duration}
  end

  defimpl Sonority do

    def duration(rest) do
      rest.duration
    end

    def type(_) do :chord end

  end
end
