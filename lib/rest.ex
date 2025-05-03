defmodule Rest do
  @type t :: %__MODULE__{
      duration: float(),
  }

  defstruct [:duration]

  @spec new(any()) :: Sonority.t()
  def new(duration) do
    # Return the struct with specified values
    %__MODULE__{
      duration: duration,
    }
  end

  defimpl Sonority do
    def duration(rest) do
      rest.duration
    end

    def type(_) do :rest end

  end
end
