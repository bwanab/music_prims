defmodule ChordPrims do
  require Logger


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

  def all_chord_sym_map() do
    @all_chord_sym_map
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



end
