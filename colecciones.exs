defmodule Colecciones do
  @moduledoc """
  Funciones puras para preparar colecciones auxiliares.
  """

  def recolectores_por_codigo(recolectores) do
    Enum.reduce(recolectores, %{}, fn recolector, acumulador ->
      Map.put(acumulador, recolector.codigo, recolector)
    end)
  end

  def lotes_por_id(lotes) do
    Enum.reduce(lotes, %{}, fn lote, acumulador ->
      Map.put(acumulador, lote.id, lote)
    end)
  end
end
