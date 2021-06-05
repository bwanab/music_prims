defmodule ChordPrims do
  import MusicPrims

  @type chord :: {atom, atom}

  @major_chord_syms [:I, :II, :III, :IV, :V, :VI, :VII]
  @minor_chord_syms [:i, :ii, :iii, :iv, :v, :vi, :vii]
  @dim_chord_syms [:i0, :ii0, :iii0, :iv0, :v0, :vi0, :vii0]

  @major_chord_sym_map Enum.map(Enum.with_index(@major_chord_syms), fn {k,v} -> {k, {v, :major}} end)
  @minor_chord_sym_map Enum.map(Enum.with_index(@minor_chord_syms), fn {k,v} -> {k, {v, :minor}} end)
  @dim_chord_sym_map Enum.map(Enum.with_index(@dim_chord_syms), fn {k,v} -> {k, {v, :diminished}} end)
  @all_chord_sym_map @major_chord_sym_map ++ @minor_chord_sym_map ++ @dim_chord_sym_map |> Enum.into(%{})
  @chord_type_map %{:major => &major_chord/2, :minor => &minor_chord/2, :diminished => &diminished_chord/2 }

  @spec chord_sym_to_chord(atom, atom) :: [atom]
  def chord_sym_to_chord(sym, key) do
    scale = major_scale(key) |> Enum.map(fn {n, _o} -> n end)
    {index, scale_type} = @all_chord_sym_map[sym]
    {Enum.at(scale, index), scale_type}
  end

  @spec chord_syms_to_chords([atom], atom) :: [atom]
  def chord_syms_to_chords(sym_seq, key) do
    Enum.map(sym_seq, fn sym -> chord_sym_to_chord(sym, key) end)
  end

  @spec chord_to_notes(chord) :: MusicPrims.note_sequence
  def chord_to_notes({key, scale_type}) do
    @chord_type_map[scale_type].(key, 1)
  end

end
