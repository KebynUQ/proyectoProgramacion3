# Integrantes: Laura, Mariana, Kebyn y Juan

defmodule Validacion do
  @moduledoc """
  Valida los pesajes de la finca en el orden exigido por el parcial.
  """

  @dias_cosecha 6
  @maximo_kilos 250

  def validar_pesaje(pesaje, recolectores_por_codigo, lotes_por_id) do
    with {:ok, pesaje} <- validar_recolector(pesaje, recolectores_por_codigo),
         {:ok, pesaje} <- validar_lote(pesaje, lotes_por_id),
         {:ok, pesaje} <- validar_dia(pesaje),
         {:ok, pesaje} <- validar_kilos(pesaje),
         {:ok, pesaje} <- validar_porcentaje(pesaje) do
      {:ok, pesaje}
    end
  end

  def separar_pesajes(pesajes, recolectores_por_codigo, lotes_por_id) do
    Enum.reduce(pesajes, {[], []}, fn pesaje, {validos, rechazados} ->
      case validar_pesaje(pesaje, recolectores_por_codigo, lotes_por_id) do
        {:ok, pesaje_valido} ->
          {validos ++ [pesaje_valido], rechazados}

        {:error, motivo} ->
          {validos, rechazados ++ [{pesaje, motivo}]}
      end
    end)
  end

  def convertir_linea_pesaje(linea) do
    campos =
      linea
      |> String.split(";")
      |> Enum.map(fn campo -> String.trim(campo) end)

    case campos do
      [recolector, lote, dia_texto, kilos_texto, verdes_texto] ->
        with {:ok, dia} <- convertir_entero(dia_texto),
             {:ok, kilos} <- convertir_numero(kilos_texto),
             {:ok, verdes} <- convertir_numero(verdes_texto) do
          {:ok,
           %{
             recolector: recolector,
             lote: lote,
             dia: dia,
             kilos: kilos,
             verdes: verdes
           }}
        end

      _ ->
        {:error, :formato_invalido}
    end
  end

  defp validar_recolector(pesaje, recolectores_por_codigo) do
    case Map.get(recolectores_por_codigo, pesaje.recolector) do
      nil -> {:error, :recolector_desconocido}
      _ -> {:ok, pesaje}
    end
  end

  defp validar_lote(pesaje, lotes_por_id) do
    case Map.get(lotes_por_id, pesaje.lote) do
      nil -> {:error, :lote_desconocido}
      _ -> {:ok, pesaje}
    end
  end

  defp validar_dia(%{dia: dia} = pesaje) when dia in 1..@dias_cosecha do
    {:ok, pesaje}
  end

  defp validar_dia(_pesaje) do
    {:error, :dia_invalido}
  end

  defp validar_kilos(%{kilos: kilos} = pesaje)
       when kilos > 0 and kilos <= @maximo_kilos do
    {:ok, pesaje}
  end

  defp validar_kilos(_pesaje) do
    {:error, :kilos_fuera_de_rango}
  end

  defp validar_porcentaje(%{verdes: verdes} = pesaje)
       when verdes >= 0 and verdes <= 100 do
    {:ok, pesaje}
  end

  defp validar_porcentaje(_pesaje) do
    {:error, :porcentaje_invalido}
  end

  defp convertir_entero(texto) do
    case Integer.parse(texto) do
      {numero, ""} -> {:ok, numero}
      _ -> {:error, :formato_invalido}
    end
  end

  defp convertir_numero(texto) do
    case Float.parse(texto) do
      {numero, ""} -> {:ok, numero}
      _ -> {:error, :formato_invalido}
    end
  end
end
