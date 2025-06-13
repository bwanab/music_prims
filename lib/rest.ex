defmodule Rest do
  @type t :: %__MODULE__{
      duration: number(),
      channel: integer()
  }

  defstruct [:duration, :channel]

  @spec new(number(), integer()) :: Sonority.t()
  def new(duration, channel \\ 0) do
    # Return the struct with specified values
    %__MODULE__{
      duration: duration,
      channel: channel
    }
  end

  def to_midi(rest) do
    rest.duration
  end

  defimpl Sonority do
    def copy(rest, opts \\ []) do
      duration = Keyword.get(opts, :duration, rest.duration)
      channel = Keyword.get(opts, :channel, rest.channel)
      Rest.new(duration, channel)
    end

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

    def channel(s) do
      s.channel
    end
 end
end
