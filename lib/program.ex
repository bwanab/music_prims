defmodule Program do
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
    def copy(program, opts \\ []) do
      value = Keyword.get(opts, :value, program.value)
      channel = Keyword.get(opts, :channel, program.channel)
      Program.new(value, channel)
    end

    def duration(_pb), do: 0
    def type(_), do: :program
    def show(_pb, _opts), do: ""
    def to_notes(_pb), do: []

    def channel(pb), do: pb.channel
  end

end
