defmodule Scale do
  @moduledoc """
  Functions for working with musical scales.
  """

  @type scale :: [Note.t()]

  @type scale_type :: :major | :dorian | :phrygian | :lydian | :mixolodian | :minor | :locrian

  # Scale intervals
  @pent_intervals [0, 3, 5, 7, 10]
  @blues_intervals [0, 3, 5, 6, 7, 10]
  @major_intervals [0, 2, 4, 5, 7, 9, 11]
  @modes [major: 0, dorian: 1, phrygian: 2, lydian: 3, mixolodian: 4, minor: 5, locrian: 6]

  # Circle of fifths and key mapping
  @notes [:C, :C!, :D, :D!, :E, :F, :F!, :G, :G!, :A, :A!, :B]
  @circle_of_fifths [:C, :G, :D, :A, :E, :B, :F!, :C!, :G!, :D!, :A!, :F]
  @circle_of_fourths Enum.reverse(@circle_of_fifths)
  @flat_circle_of_fifths [:C, :G, :D, :A, :E, :B, :Gb, :Db, :Ab, :Eb, :Bb, :F]
  @normal_flat [:G!, :D!, :A!, :F, :Gb, :Db, :Ab, :Eb, :Bb]
  @flats [:Gb, :Db, :Ab, :Eb, :Bb]

  # @flat_key_map Enum.zip(@circle_of_fifths, @flat_circle_of_fifths) |> Enum.into(%{})
  # @normal_flat_key_map @flat_key_map |> Map.merge(%{:F! => :F!, :C! => :C!})
  @sharp_key_map Enum.zip(@flat_circle_of_fifths, @circle_of_fifths) |> Enum.into(%{})

  def new(key, quality \\ :major, octave \\ 3) do
    build_note_seq(key, @major_intervals |> rotate_zero(@modes[quality]), octave)
  end

  def normal_flat_set() do
    @normal_flat |> MapSet.new()
  end

  @doc """
  Get the scale intervals for the given mode.
  """
  @spec scale_interval(atom) :: [integer]
  def scale_interval(mode) do
    mode_num = @modes[mode]
    @major_intervals |> rotate_zero(mode_num)
  end

  @doc """
  Build a chromatic scale starting from the given note.
  """
  @spec chromatic_scale(Note) :: scale()
  def chromatic_scale(%Note{} = note) do
    Enum.reduce(0..11, [note], fn _, [last | _] = acc ->
      next = next_half_step(last)
      # Map sharp notes to flat notes where appropriate
      mapped_note = case {next.note, next.octave} do
        {:D!, o} -> %{next | note: :Eb, octave: o}
        {:G!, o} -> %{next | note: :Ab, octave: o}
        {:A!, o} -> %{next | note: :Bb, octave: o}
        _ -> next
      end
      [mapped_note | acc]
    end)
    |> Enum.reverse()
  end
  def chromatic_scale(key, octave) do
    chromatic_scale(Note.new(key, octave))
  end

  @doc """
  Build a scale from the given key and mode.
  """
  @spec modal_scale(atom, integer, atom) :: scale
  def modal_scale(key, octave, mode) do
    build_note_seq(key, @major_intervals |> rotate_zero(@modes[mode]), octave)
  end

  @spec major_scale(atom, integer) :: scale
  def major_scale(key, octave \\ 0) do
    build_note_seq(key, @major_intervals, octave)
  end

  @spec minor_scale(atom, integer) :: scale
  def minor_scale(key, octave \\ 0) do
    build_note_seq(key, @major_intervals |> rotate_zero(@modes[:minor]), octave)
  end

  @spec blues_scale(atom, integer) :: scale
  def blues_scale(key, octave \\ 0) do
    build_note_seq(key, @blues_intervals, octave)
  end

  @spec pent_scale(atom, integer) :: scale
  def pent_scale(key, octave \\ 0) do
    build_note_seq(key, @pent_intervals, octave)
  end

  @doc """
  Build a sequence of notes from a key and intervals.
  """
  @spec build_note_seq(atom, [integer], integer) :: scale
  def build_note_seq(key, intervals, octave \\ 0) do
    map_by_flat_key(key)
    |> Note.new(octave: octave)
    |> chromatic_scale()
    |> raw_scale(intervals)
    # IO.inspect(rs)
    # raw_seq = map_by_key(rs, key)
    # IO.inspect(raw_seq)
    # # Convert to Note structs with quarter note durations (1) and velocity of 100
    # Enum.map(raw_seq, fn raw_note ->
    #   Note.new(raw_note, octave, 1, 100)
    # end)
  end

  @doc """
  Adjust the octave of a scale by the given octave amount.
  """
  @spec adjust_octave(scale, integer) :: scale
  def adjust_octave(scale, octave) when octave == 0, do: scale
  def adjust_octave(scale = [%Note{} | _], octave) do
    Enum.map(scale, fn %Note{note: {note, o}} = n -> %{n | note: {note, o + octave}} end)
  end
  def adjust_octave(scale, octave) do
    Enum.map(scale, fn {note, o} -> {note, o + octave} end)
  end

  @doc """
  Rotate a list of integers by the given amount.
  """
  @spec rotate([integer], integer) :: [integer]
  def rotate(intervals, by) do
    Enum.drop(intervals, by) ++ (Enum.take(intervals, by) |> Enum.map(&(&1 + 12)))
  end

  @doc """
  Rotate a list of integers by the given amount and return the result with the first element set to 0.
  """
  @spec rotate_zero([integer], integer) :: [integer]
  def rotate_zero(intervals, by) do
    [f|r] = rotate(intervals, by)
    [0|Enum.map(r, &(&1 - f))]
  end

  @doc """
  Rotate a list of notes by the given amount.
  """
  @spec rotate_notes([Note.t()], integer) :: [Note.t()]
  def rotate_notes(notes, n) do
    {l, r} = Enum.split(notes, n)
    r ++ Enum.map(l, fn
      %Note{note: key, octave: octave} -> Note.new(key, octave: octave + 1)
      {key, octave} -> Note.new(key, octave: octave + 1)
    end)
  end

  @doc """
  Rotate a list of notes by the given amount around a specific key.
  """
  @spec rotate_octave_around(scale, atom) :: scale
  def rotate_octave_around([f|rest], key) when is_tuple(f) do
    scale = [f|rest]
    rotate_octave(scale, Enum.find_index(scale, fn {note, _} -> note == key end))
  end
  def rotate_octave_around([f|rest], key) do
    scale = [f|rest]
    rotate_octave(scale, Enum.find_index(scale, fn note -> note == key end))
  end

  @spec rotate_octave(scale, integer) :: scale
  def rotate_octave([f|rest], by) when is_tuple(f) do
    scale = [f|rest]
    Enum.drop(scale, by) ++ Enum.map(Enum.take(scale, by), fn {note, midi} -> {note, midi + 12} end)
  end
  def rotate_octave([f|rest], by) do
    scale = [f|rest]
    Enum.drop(scale, by) ++ Enum.map(Enum.take(scale, by), fn midi -> midi + 12 end)
  end

  @doc """
  Build a raw scale from a chromatic scale and intervals.
  """
  @spec raw_scale(scale, [integer]) :: scale
  def raw_scale(chromatic_scale, intervals) do
    Enum.map(intervals, fn interval ->
      if interval < 12 do
        Enum.at(chromatic_scale, interval)
      else
        Enum.at(chromatic_scale, interval - 12)
        |> Note.octave_up
      end
    end)
  end

  # Helper functions from MusicPrims
  defp map_by_flat_key(%Note{note: {key, octave}} = note) do
    mapped_key = map_by_flat_key(key)
    %{note | note: {mapped_key, octave}}
  end

  defp map_by_flat_key(nk) do
    if MapSet.member?(MapSet.new(@flats), Note.key_from_note(nk)) do
      new_key = Map.get(@sharp_key_map, Note.key_from_note(nk))
      if is_tuple(nk), do: Note.new(new_key, octave: elem(nk, 1)), else: new_key
    else
      nk
    end
  end

  # defp map_by_key(seq, key) do
  #   if MapSet.member?(MapSet.new(@normal_flat), Note.key_from_note(key)) do
  #     Enum.map(seq, &map_by_sharp_key/1)
  #   else
  #     Enum.map(seq, &map_by_flat_key/1)
  #   end
  # end

  # defp map_by_sharp_key(nk, context \\ :normal)
  # defp map_by_sharp_key(%Note{note: {key, octave}} = note, context) do
  #   mapped_key = map_by_sharp_key(key, context)
  #   %{note | note: {mapped_key, octave}}
  # end
  # defp map_by_sharp_key(nk, context) do
  #   key_map = if context == :normal, do: @normal_flat_key_map, else: @flat_key_map
  #   k = case Map.get(key_map, Note.key_from_note(nk)) do
  #     nil -> Note.key_from_note(nk)
  #     val -> val
  #   end
  #   if is_tuple(nk), do: Note.new(k, elem(nk, 1)), else: k
  # end


  @doc """
  Get the key for which notes for the given key and mode are the same.
  E.G. for :A, :minor, :major, we would return :C since the notes of A-minor are the
  same as the notes in C major.
       for :D :dorian, :major we would return :C
       for :D :dorian, :minor we would return :A
  """
  @spec equivalent_key(atom, atom, atom) :: Note.t()
  def equivalent_key(key, key_mode, equivlent_mode) do
    index = @modes[equivlent_mode] - @modes[key_mode]
    Enum.at(modal_scale(key, 0, key_mode), index).note
  end


  @spec scale_notes([integer]) :: [Note.t()]
  def scale_notes(intervals) do
    Enum.map(intervals, fn interval -> Enum.at(MusicPrims.midi_notes(), interval) end)
  end

  @spec scale_notes_note([integer]) :: [atom]
  def scale_notes_note(scale) do
    Enum.map(scale_notes(scale), fn {note, _midi} -> note end)
  end

  @spec scale_notes_midi([integer]) :: [integer]
  def scale_notes_midi(scale) do
    Enum.map(scale_notes(scale), fn {_note, midi} -> midi end)
  end


  def enharmonic_equal?(scale1, scale2) do
    Enum.all?(Enum.map(Enum.zip(scale1, scale2),
              fn {a, b} -> Note.enharmonic_equal?(a, b) end))
  end

  @doc """
  Get the next note in the given circle.
  """
  @spec next_nth(Note.t(), [atom()]) :: Note.t()
  def next_nth(%Note{note: key, octave: octave} = note, circle) do
    idx = Enum.find_index(circle, &(Note.enharmonic_equal?(key, &1)))
    {next_key, octave} = case idx do
      nil -> {key, octave}
      ^idx when idx == length(circle) - 1 -> {Enum.at(circle, 0), octave + 1}
      ^idx -> {Enum.at(circle, idx + 1), octave}
    end
    %{note | note: next_key, octave: octave}
  end

  @doc """
  Get the next note in the circle of fifths.
  """
  @spec next_fifth(Note.t()) :: Note.t()
  def next_fifth(note) do
    next_nth(note, @circle_of_fifths)
  end

  @doc """
  Get the next note in the circle of fourths.
  """
  @spec next_fourth(Note.t()) :: Note.t()
  def next_fourth(note) do
    next_nth(note, @circle_of_fourths)
  end

  @doc """
  Get the next note in the circle of fourths.
  """
  @spec next_half_step(Note.t()) :: Note.t()
  def next_half_step(note) do
    next_nth(note, @notes)
  end


end
