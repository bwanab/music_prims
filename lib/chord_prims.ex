defmodule ChordPrims do
  require Logger
  import MusicPrims

  @type chord_sym :: {{atom(), integer()}, atom()}

  @major_chord_syms [:I, :II, :III, :IV, :V, :VI, :VII]
  @minor_chord_syms [:i, :ii, :iii, :iv, :v, :vi, :vii]
  @dim_chord_syms [:i0, :ii0, :iii0, :iv0, :v0, :vi0, :vii0]
  @dominant_seventh_chord_syms [:I7, :II7, :III7, :IV7, :V7, :VI7, :VII7]
  @major_seventh_chord_syms [:Imaj7, :IImaj7, :IIImaj7, :IVmaj7, :Vmaj7, :VImaj7, :VIImaj7]
  @minor_seventh_chord_syms [:i7, :ii7, :iii7, :iv7, :v7, :vi7, :vii7]

  @major_chord_sym_map Enum.map(Enum.with_index(@major_chord_syms), fn {k,v} -> {k, {v, :major}} end)
  @minor_chord_sym_map Enum.map(Enum.with_index(@minor_chord_syms), fn {k,v} -> {k, {v, :minor}} end)
  @dim_chord_sym_map Enum.map(Enum.with_index(@dim_chord_syms), fn {k,v} -> {k, {v, :diminished}} end)
  @dominant_seventh_chord_sym_map Enum.map(Enum.with_index(@dominant_seventh_chord_syms), fn {k,v} -> {k, {v, :dominant_seventh}} end)
  @major_seventh_chord_sym_map Enum.map(Enum.with_index(@major_seventh_chord_syms), fn {k,v} -> {k, {v, :major_seventh}} end)
  @minor_seventh_chord_sym_map Enum.map(Enum.with_index(@minor_seventh_chord_syms), fn {k,v} -> {k, {v, :minor_seventh}} end)
  @all_chord_sym_map @major_chord_sym_map
  ++ @minor_chord_sym_map
  ++ @dim_chord_sym_map
  ++ @major_seventh_chord_sym_map
  ++ @minor_seventh_chord_sym_map
  ++ @dominant_seventh_chord_sym_map |> Enum.into(%{})
  @chord_type_map %{:major => &major_chord/2,
                    :minor => &minor_chord/2,
                    :diminished => &diminished_chord/2,
                    :dominant_seventh => &dominant_seventh_chord/2,
                    :major_seventh => &major_seventh_chord/2,
                    :minor_seventh => &minor_seventh_chord/2
  }

  def major_diatonic_progression() do [:I, :ii, :iii, :IV, :V, :vi, :vii0] end
  def minor_diatonic_progression() do [:i, :ii0, :III, :iv, :v, :VI, :VII] end

  def table_of_usual_progressions() do

    %{
      1 => [4, 5, 6, 2, 3],
      2 => [5, 4, 6, 1, 3],
      3 => [6, 4, 1, 2, 5],
      4 => [5, 1, 2, 3, 6],
      5 => [1, 4, 6, 2, 3],
      6 => [2, 5, 3, 4, 1],
      7 => [1, 3, 6, 2, 4]
    }
  end

  # results in a list of indices where each index is repeated n times. So, there will be 10 * 0, 8 * 1, 4 * 2, etc.
  @usual_odds Enum.with_index([10, 8, 4, 3, 1]) |> Enum.reduce([], fn {x, i}, acc -> acc ++ (Stream.repeatedly(fn () -> i end) |> Enum.take(x)) end)

  @spec usual_odds() :: [integer]
  def usual_odds() do @usual_odds end


  @spec random_progression(integer, integer, [atom]) :: [atom]
  def random_progression(len, start, progression \\ major_diatonic_progression()) do
    Stream.iterate(start, &(random_next(&1)))
    |> Enum.take(len)
    |> Enum.map(&(Enum.at(progression, &1 - 1)))
  end

  @spec random_progression_to_root(integer, [atom]) :: [atom]
  def random_progression_to_root(start \\ 1, progression \\ major_diatonic_progression()) do
    Stream.iterate(start, &(random_next(&1)))
    |> Enum.take(50) # arbitrarily long value such that the root chord should repeat.
    |> Enum.drop(1)  # since the first one is the start
    |> Enum.take_while(&(&1 != start)) # take up until the start is found in the progression
    |> List.insert_at(0, start)  # add the start back into the beginning.
    |> Enum.map(&(Enum.at(progression, &1 - 1)))
  end

  @spec random_next(integer) :: integer
  def random_next(start) do
    index = Enum.random(@usual_odds)
    table_of_usual_progressions()[start] |> Enum.at(index)
   end

  @spec roman_numeral_to_chord(atom(), {Note.t() | {atom(), integer()}, atom()}) :: chord_sym
  def roman_numeral_to_chord(sym, {{key, octave}, scale_type}) do
    scale = if scale_type == :major do
      major_scale(key, octave)
    else
      minor_scale(key, octave)
    end

    # Extract just the note names from the scale
    note_names = scale |> Enum.map(fn
      %Note{note: {n, _o}} -> n
      {n, _o} -> n
    end)

    {index, chord_type} = @all_chord_sym_map[sym]
    chord_key = Enum.at(note_names, index)

    # Keep the same format as input - full tuple with octave
    {{chord_key, octave}, chord_type}
  end

  def roman_numeral_to_chord(sym, {%Note{note: {key, octave}}, scale_type}) do
    roman_numeral_to_chord(sym, {{key, octave}, scale_type})
  end

  @spec chord_syms_to_chords([atom], chord_sym) :: [chord_sym]
  def chord_syms_to_chords(sym_seq, chord) do
    Enum.map(sym_seq, fn sym -> roman_numeral_to_chord(sym, chord) end)
  end

  @spec chord_to_notes(chord_sym) :: MusicPrims.note_sequence
  def chord_to_notes({{key, octave}, scale_type}) do
    @chord_type_map[scale_type].(key, octave)
  end

  def chord_to_notes({key, scale_type}) when is_atom(key) and is_atom(scale_type) do
    # Default to octave 0 if only key is given
    @chord_type_map[scale_type].(key, 0)
  end

  @spec chords_to_notes([chord_sym]) :: [MusicPrims.note_sequence]
  def chords_to_notes(chords) do
    Enum.map(chords, &(chord_to_notes(&1)))
  end

  @spec chord_sym_to_midi(atom, chord_sym) :: [integer]
  def chord_sym_to_midi(sym, chord) do
    roman_numeral_to_chord(sym, chord)
    |> chord_to_notes
    |> to_midi
  end

  @spec chord_syms_to_midi([atom], chord_sym) :: [[integer]]
  def chord_syms_to_midi(sym_seq, chord) do
    Enum.map(sym_seq, &(chord_sym_to_midi(&1, chord)))
  end

  @spec chord_common_notes(chord_sym, chord_sym, boolean) :: integer
  def chord_common_notes(c1, c2, ignore_octave \\ :true) do
    common_notes(chord_to_notes(c1), chord_to_notes(c2), ignore_octave)
  end

  @spec common_notes(MusicPrims.note_sequence, MusicPrims.note_sequence, boolean) :: integer
  def common_notes(c1, c2, ignore_octave \\ :true)

  def common_notes(c1, c2, ignore_octave) when ignore_octave == :false do
    case List.myers_difference(c1, c2)[:eq] do
      nil -> []
      val -> val
    end
    |> Enum.count
  end

  def common_notes(c1, c2, ignore_octave) when ignore_octave == :true do
    case List.myers_difference(Enum.map(c1, &key_from_note(&1)), Enum.map(c2, &key_from_note(&1)))[:eq] do
      nil -> []
      val -> val
    end
    |> Enum.count
  end


  @spec note_distance(Note.t(), Note.t()) :: integer
  def note_distance(n1, n2) do
    v =
      Stream.iterate(abs(to_midi(n1) - to_midi(n2)), &(&1 - 12))
      |> Stream.drop_while(&(&1 > 12))
      |> Enum.take(1)
      |> List.first
    if v > 6 do 12 - v else v end
  end

  @spec compute_one_flow(MusicPrims.note_sequence, MusicPrims.note_sequence) :: integer
  def compute_one_flow(c1, c2) do
    Enum.zip(c1, c2)
    # |> IO.inspect
    |> Enum.map(fn {n1, n2} ->
      note_distance(n1, n2)
    end)
    # |> IO.inspect
    |> Enum.sum
  end

  @doc """
  compute the full distance that separates two chords.
  For example: {{:C, 4}, :major} to {{:A, 4}, :minor}
    The notes of C4 maj are C,E,G
    The notes of F4 min are A,C,E

    since C and E are shared there's no distance, but the distance from
    G to A is 2 semitones, thus the full distance is 2 for the chord.

  Example 2: {{:C, 4}, :major} to {{:D, 4}, :major}
    The notes of C4 maj are C,E,G
    The notes of D4 maj are D,F!,A

    Each of the pairs {C,D}, {E,F!} and {G,A} are 2 semitones each so
    the full distance is 6

  I truthfully don't know why this is a worthwhile measure and don't remember
  why I added it in the first place.
  """
  def compute_flow(c1, c2) when is_list(c1) and is_list(c2) do
    n = length(c2) - 1
    Enum.map(0..n, &(rotate_any(c2, &1)))
    # |> IO.inspect
    |> Enum.map(fn c2p -> compute_one_flow(c1, c2p) end)
    # |> IO.inspect
    |> Enum.min
  end

  def compute_flow(c1, c2) do
    compute_flow(chord_to_notes(c1), chord_to_notes(c2))
  end

  def compute_flow(p) do
    sum = Enum.zip(p, rotate_any(p, 1))
    |> Enum.map(fn {a, b} ->
      compute_flow(
        roman_numeral_to_chord(a, {{:G, 0}, :major}),
        roman_numeral_to_chord(b, {{:G, 0}, :major}))
    end)
    |> Enum.sum
    sum / length(p)
  end
end
