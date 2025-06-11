defmodule PitchBend do
  @moduledoc """
  Functions for working with MIDI pitch bend events.
  """

  @type t :: %__MODULE__{
    value: integer(),
    channel: integer()
  }

  defstruct [:value, :channel]

  def new(channel, value) do
    %__MODULE__{channel: channel, value: value}
  end

  # Implement the Sonority protocol
  defimpl Sonority do
    def duration(_pb), do: 0
    def type(_), do: :pitch_bend
    def show(_pb, _opts), do: ""
    def to_notes(_pb), do: []

    def channel(pb), do: pb.channel
  end

end