defmodule PolyPress do
  @moduledoc """
  Functions for working with MIDI polyphonic pressure events.
  """

  @type t :: %__MODULE__{
    note_number: integer(),
    value: integer(),
    channel: integer()
  }

  defstruct [:note_number, :value, :channel]

  def new(channel, note_number, value) do
    %__MODULE__{channel: channel, note_number: note_number, value: value}
  end

  # Implement the Sonority protocol
  defimpl Sonority do
    def copy(poly_press, opts \\ []) do
      note_number = Keyword.get(opts, :note_number, poly_press.note_number)
      value = Keyword.get(opts, :value, poly_press.value)
      channel = Keyword.get(opts, :channel, poly_press.channel)
      PolyPress.new(channel, note_number, value)
    end

    def duration(_pp), do: 0
    def type(_), do: :poly_press
    def show(_pp, _opts), do: ""
    def to_notes(_pp), do: []

    def channel(pp), do: pp.channel
  end

end
