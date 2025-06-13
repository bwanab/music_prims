defmodule ChanPress do
  @moduledoc """
  Functions for working with MIDI channel pressure events.
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
    def copy(chan_press, opts \\ []) do
      value = Keyword.get(opts, :value, chan_press.value)
      channel = Keyword.get(opts, :channel, chan_press.channel)
      ChanPress.new(value, channel)
    end

    def duration(_cp), do: 0
    def type(_), do: :chan_press
    def show(_cp, _opts), do: ""
    def to_notes(_cp), do: []

    def channel(cp), do: cp.channel
  end

end
