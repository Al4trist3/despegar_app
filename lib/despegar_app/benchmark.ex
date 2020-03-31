defmodule Benchmark do

@moduledoc """
Toma los argumentos y una funcion, la ejecuta calculando el tiempo de ejecucion.
Devuelve el tiempo en segundos.
"""
  def measure(args, function) do
    function
    |> :timer.tc([args])
    |> elem(0)
    |> Kernel./(1_000_000)
    |> IO.puts
  end
end