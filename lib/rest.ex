defmodule Rest do
  @behaviour Sonority
    @type t :: %__MODULE__{
      duration: float(),
  }

  defstruct [:duration]

  def new(duration) do
    # Return the struct with specified values
    %__MODULE__{
      duration: duration,
    }
  end

  @impl Sonority
  def duration(rest) do
    rest.duration
  end

  @impl Sonority
  def type() do :rest end

end
