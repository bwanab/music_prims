defmodule Scale do
  @moduledoc """
  Functions for working with musical scales.
  """

  @type scale :: [Note.t()]

  # Scale intervals
  @pent_intervals [0, 3, 5, 7, 10]
  @blues_intervals [0, 3, 5, 6, 7, 10]
  @major_intervals [0, 2, 4, 5, 7, 9, 11]
  @modes [major: 0, dorian: 1, phrygian: 2, lydian: 3, mixolodian: 4, minor: 5, locrian: 6]

  # Circle of fifths and key mapping
  @circle_of_fifths [:C, :G, :D, :A, :E, :B, :F!, :C!, :G!, :D!, :A!, :F]
  @flat_circle_of_fifths [:C, :G, :D, :A, :E, :B, :Gb, :Db, :Ab, :Eb, :Bb, :F]
  @normal_flat [:G!, :D!, :A!, :F, :Gb, :Db, :Ab, :Eb, :Bb]
  @flats [:Gb, :Db, :Ab, :Eb, :Bb]

  @flat_key_map Enum.zip(@circle_of_fifths, @flat_circle_of_fifths) |> Enum.into(%{})
  @normal_flat_key_map @flat_key_map |> Map.merge(%{:F! => :F!, :C! => :C!})
  @sharp_key_map Enum.zip(@flat_circle_of_fifths, @circle_of_fifths) |> Enum.into(%{})

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
    skey = map_by_flat_key(key)
    raw_seq = Note.chromatic_scale(Note.new({skey, octave}))
    |> raw_scale(intervals)
    |> map_by_key(key)

    # Convert to Note structs with quarter note durations (1) and velocity of 100
    Enum.map(raw_seq, fn raw_note ->
      Note.new(raw_note, duration: 1, velocity: 100)
    end)
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
      %Note{note: {key, octave}} -> Note.new({key, octave + 1})
      {key, octave} -> Note.new({key, octave + 1})
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
    if MapSet.member?(MapSet.new(@flats), key_from_note(nk)) do
      new_key = Map.get(@sharp_key_map, key_from_note(nk))
      if is_tuple(nk), do: Note.new({new_key, elem(nk, 1)}), else: new_key
    else
      nk
    end
  end

  defp map_by_key(seq, key) do
    if MapSet.member?(MapSet.new(@normal_flat), key_from_note(key)) do
      Enum.map(seq, &map_by_sharp_key/1)
    else
      Enum.map(seq, &map_by_flat_key/1)
    end
  end

  defp map_by_sharp_key(nk, context \\ :normal)
  defp map_by_sharp_key(%Note{note: {key, octave}} = note, context) do
    mapped_key = map_by_sharp_key(key, context)
    %{note | note: {mapped_key, octave}}
  end
  defp map_by_sharp_key(nk, context) do
    key_map = if context == :normal, do: @normal_flat_key_map, else: @flat_key_map
    k = case Map.get(key_map, key_from_note(nk)) do
      nil -> key_from_note(nk)
      val -> val
    end
    if is_tuple(nk), do: Note.new({k, elem(nk, 1)}), else: k
  end


  @doc """
  Get the key for which notes for the given key and mode are the same.
  E.G. for :A, :minor, :major, we would return :C since the notes of A-minor are the
  same as the notes in C major.
       for :D :dorian, :major we would return :C
       for :D :dorian, :minor we would return :A
  """
  @spec equivalent_key(atom, atom, atom) :: atom
  def equivalent_key(key, key_mode, equivlent_mode) do
    index = @modes[equivlent_mode] - @modes[key_mode]
    {rkey, _} = Enum.at(modal_scale(key, 0, key_mode), index).note
    rkey
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

  defp key_from_note(n) when is_atom(n), do: n
  defp key_from_note(%Note{note: {key, _o}}), do: key
end
