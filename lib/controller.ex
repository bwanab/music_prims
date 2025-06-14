defmodule Controller do
  @moduledoc """
  Functions for working with musical notes.
  """

  @type t :: %__MODULE__{
    controller_number: integer(),
    value: integer(),
    channel: integer()
  }

  defstruct [:controller_number, :value, :channel]

  def new(controller_number, value, channel) do
    %__MODULE__{controller_number: controller_number, value: value, channel: channel}
  end

  # Implement the Sonority protocol
  defimpl Sonority do
    def copy(controller, opts \\ []) do
      controller_number = Keyword.get(opts, :controller_number, controller.controller_number)
      value = Keyword.get(opts, :value, controller.value)
      channel = Keyword.get(opts, :channel, controller.channel)
      Controller.new(controller_number, value, channel)
    end
    def duration(_c), do: 0
    def type(_), do: :controller
    def show(_c, _opts), do: ""
    def to_notes(_c), do: []

    def channel(c), do: c.channel
  end

end
