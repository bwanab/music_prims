defmodule MusicPrims do
  require Logger

  @circle_of_fifths [:C, :G, :D, :A, :E, :B, :F!, :C!, :G!, :D!, :A!, :F]
  @pent_intervals [0, 3, 5, 7, 10]
  @blues_intervals [0, 3, 5, 6, 7, 10]
  @major_intervals [0, 2, 4, 5, 7, 9, 11]
  @modes [:major, :dorian, :phrygian, :lydian, :mixolodian, :minor, :lociran]
  @scale_intervals Enum.into(Enum.zip(@modes, @major_intervals), %{})

  @midi_notes [{:C, 24}, {:C!, 25}, {:D, 26}, {:D!, 27}, {:E, 28}, {:F, 29}, {:F!, 30},
               {:G, 31}, {:G!, 32}, {:A, 33}, {:A!, 34}, {:B, 35}]

  @notes_by_midi Enum.into(Enum.map(@midi_notes, fn {note, midi} -> {midi, note} end), %{})
  @midi_notes_map Enum.into(@midi_notes, %{})

  def key(mode, n_sharps_flats) when mode == :major do
    Enum.at(@circle_of_fifths, n_sharps_flats)
  end
  def key(mode, n_sharps_flats) when mode == :minor do
    Enum.at(@circle_of_fifths, n_sharps_flats+3)
  end

  def gt(key1, key2) do
    Logger.info("#{key1} #{@midi_notes_map[key1]} #{key2} #{@midi_notes_map[key2]}")
    @midi_notes_map[key1] > @midi_notes_map[key2]
  end

  @doc """
  Kind of arbitrary that the octave cutoff is always at C.
  """
  def next_nth({key, octave}, circle) do
    index = Enum.find_index(circle, fn x -> x == key end) + 1
    new_key = Enum.at(circle, if index >= length(circle) do 0 else index end)
    octave_up = if gt(key, new_key) do 1 else 0 end
    {new_key, octave + octave_up}
   end

  def next_fifth({key, octave}) do
    next_nth({key, octave}, @circle_of_fifths)
  end

  def next_fourth({key, octave}) do
    next_nth({key, octave}, Enum.reverse(@circle_of_fifths))
  end

  def rotate(scale, by) do
    Enum.drop(scale, by) ++ Enum.take(scale, by)
  end

  def rotate_octave([f|rest], by) when is_tuple(f) do
    scale = [f|rest]
    Enum.drop(scale, by) ++ Enum.map(Enum.take(scale, by), fn {note, midi} -> {note, midi + 12} end)
  end
  def rotate_octave([f|rest], by) do
    scale = [f|rest]
    Enum.drop(scale, by) ++ Enum.map(Enum.take(scale, by), fn midi -> midi + 12 end)
  end

  def rotate_octave_around([f|rest], key) when is_tuple(f) do
    scale = [f|rest]
    rotate_octave(scale, Enum.find_index(scale, fn {note, _} -> note == key end))
  end

  def chromatic_scale(key) do
    midi = @midi_notes_map[key]
    cmidi = @midi_notes_map[:C]
    interval = midi - cmidi
    rotate_octave(@midi_notes, interval)
  end

  # def scale_interval(scale, interval) do
  #   {note, _} = Enum.at(scale, interval)
  #   note
  # end

  def scale_interval(mode) do
    @scale_intervals[mode]
  end

  def note_map(note) do
    @midi_notes_map[note]
  end

  @doc """
  return the key for which notes for the given key and mode are the same.
  E.G. for :A, :minor, we would return :C since the notes of A-minor are the
  same as the notes in C major.
  """
  def major_key(key, mode) do
    index = note_map(key) - scale_interval(mode)
    @notes_by_midi[if index >= 24 do index else index + 12 end]
  end

  def raw_scale(chromatic_scale, intervals) do
    Enum.map(intervals, fn interval -> Enum.at(chromatic_scale, interval) end)
  end

  def adjust_octave(scale, octave) when octave == 0 do scale end
  def adjust_octave(scale, octave) do
    Enum.map(scale, fn {note, midi} -> {note, midi + 12 * octave} end)
  end

  def scale(key, mode \\ :major, octave \\ 0) do
    major_key(key, mode)
    |> build_scale(key, @major_intervals, octave)
  end

  def major_scale(key, octave \\ 0) do
    scale(key, :major, octave)
  end

  def minor_scale(key, octave \\ 0) do
    scale(key, :minor, octave)
  end

  def dorian_scale(key, octave \\ 0) do
    scale(key, :dorian, octave)
  end

  def blues_scale(key, octave \\ 0) do
    build_scale(key, key, @blues_intervals, octave)
  end

  def pent_scale(key, octave \\ 0) do
    build_scale(key, key, @pent_intervals, octave)
  end

  def build_scale(chrome_key, key, intervals, octave \\ 0) do
    chromatic_scale(chrome_key)
    |> raw_scale(intervals)
    |> rotate_octave_around(key)
    |> adjust_octave(octave)
  end

  @doc """
  produces a sequence of midi notes for the given scale function(f) in the key
  with num octaves.

  Example:

  MusicPrims.scale_seq(:D, 4, &MusicPrims.pent_scale/2)
  [26, 29, 31, 33, 36, 38, 41, 43, 45, 48, 50, 53, 55, 57, 60, 62, 65, 67, 69, 72,
   74, 77, 79, 81, 84]

  """
  def scale_seq(key, num, f) do
    Enum.map(0..num, fn x -> Enum.map(f.(key, x), fn {_, m} -> m end) end)
    |> List.flatten
  end

  def scale_notes(scale) do
    Enum.map(scale, fn interval -> Enum.at(@midi_notes, interval) end)
  end

  def scale_notes_note(scale) do
    Enum.map(scale_notes(scale), fn {note, _midi} -> note end)
  end

  def scale_notes_midi(scale) do
    Enum.map(scale_notes(scale), fn {_note, midi} -> midi end)
  end

end
