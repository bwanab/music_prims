defprotocol Sonority do
  @doc """
  In music everything that happens is in the context of the flow of time.
  At any given point in time on a given track one of 3 conditions can
  hold:
  1) a single note,
  2) a chord (i.e. multiple notes),
  3) a rest.
  Further, any flow of music can be partitioned into a
  discreet set of those events each of which has a duration.
  That is what this module type along with Note, Chord, and Rest represents.

  It's worth noting that real musical performance often blurs these boundaries. Elements like:
  1) Articulations (slurs, staccato)
  2) Continuous pitch changes (glissando, portamento)
  3) Timbral modifications (vibrato, tremolo)
  4) Dynamic changes (crescendo, diminuendo)

  Dealing with these will be at a later iteration.
"""
  @spec duration(t()) :: integer()
  def duration(s)

  @spec type(t()) :: atom()
  def type(s)

  @spec show(t(), Keyword.t()) :: String.t()
  def show(s, opts \\ [])

  @spec to_notes(t()) :: [Sonority.t()]
  def to_notes(s)

  @doc """
  Gets the type of a Sonority.

  ## Examples

      iex> note = Note.new(:C, 4)
      iex> Sonority.get_type(note)
      :note

      iex> rest = Rest.new(1.0)
      iex> Sonority.get_type(rest)
      :rest

      iex> chord = Chord.new([Note.new(:C, 4), Note.new(:E, 4), Note.new(:G, 4)], 1.0)
      iex> Sonority.get_type(chord)
      :chord
  """
end
