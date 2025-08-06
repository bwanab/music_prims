defmodule Sysex do
  @moduledoc """
  Functions for working with MIDI pitch bend events.
  """

  @type t :: %__MODULE__{
    value: [integer()],
    duration: float()
  }

  defstruct [:value, :duration]

  def new(value, duration) do
    %__MODULE__{value: value, duration: duration}
  end

  # Implement the Sonority protocol
  defimpl Sonority do
    def copy(sysex, opts \\ []) do
      value = Keyword.get(opts, :value, sysex.value)
      duration = Keyword.get(opts, :value, sysex.duration)
      Sysex.new(value, duration)
    end

    def duration(pb), do: pb.duration
    def type(_), do: :sysex
    def show(_pb, _opts), do: ""
    def to_notes(_pb), do: []

    def channel(_pb), do: 0
  end

end
