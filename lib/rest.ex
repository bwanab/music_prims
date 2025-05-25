defmodule Rest do
  @type t :: %__MODULE__{
      duration: number(),
  }

  defstruct [:duration]

  @spec new(number()) :: Sonority.t()
  def new(duration) do
    # Return the struct with specified values
    %__MODULE__{
      duration: duration,
    }
  end

  def to_midi(rest) do
    rest.duration
  end

  defimpl Sonority do
    def duration(rest) do
      rest.duration
    end

    def type(_) do :rest end

    def show(rest, _opts \\ []) do
      "r#{MidiNote.get_lily_duration(rest.duration)}"
    end

    def to_notes(r) do
      [r]
    end
 end
end
