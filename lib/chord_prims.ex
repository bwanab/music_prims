defmodule ChordPrims do
  import MusicPrims

  @type chord :: {MusicPrims.note, atom}

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

  @spec chord_sym_to_chord(atom, chord) :: chord
  def chord_sym_to_chord(sym, {{key, octave}, scale_type}) do
    scale = if scale_type == :major do
      major_scale(key, octave)
    else
      minor_scale(key, octave)
    end
    scale |> Enum.map(fn {n, _o} -> n end)
    {index, scale_type} = @all_chord_sym_map[sym]
    {Enum.at(scale, index), scale_type}
  end

  @spec chord_syms_to_chords([atom], chord) :: [chord]
  def chord_syms_to_chords(sym_seq, chord) do
    Enum.map(sym_seq, fn sym -> chord_sym_to_chord(sym, chord) end)
  end

  @spec chord_to_notes(chord) :: MusicPrims.note_sequence
  def chord_to_notes({{key, octave}, scale_type}) do
    @chord_type_map[scale_type].(key, octave)
  end

  @spec chords_to_notes([chord]) :: [MusicPrims.note_sequence]
  def chords_to_notes(chords) do
    Enum.map(chords, &(chord_to_notes(&1)))
  end

  @spec chord_sym_to_midi(atom, chord) :: [integer]
  def chord_sym_to_midi(sym, chord) do
    chord_sym_to_chord(sym, chord)
    |> chord_to_notes
    |> to_midi
  end

  @spec chord_syms_to_midi([atom], chord) :: [[integer]]
  def chord_syms_to_midi(sym_seq, chord) do
    Enum.map(sym_seq, &(chord_sym_to_midi(&1, chord)))
  end
end
