# Integrantes: Laura, Mariana, Kebyn y Juan

defmodule Liquidacion do
  @moduledoc """
  Calcula el valor de los pesajes y la liquidación de los recolectores.
  """

  @tarifa_base 1_000
  @kilos_bonificacion 120
  @bonificacion_diaria 8_000
  @descuento_alimentacion 12_000

  

  def valor_pesaje(pesaje) do
    valor_base = pesaje.kilos * @tarifa_base

    cond do
      pesaje.verdes <= 2 ->
        valor_base * 1.05

      pesaje.verdes <= 5 ->
        valor_base

      pesaje.verdes <= 10 ->
        valor_base * 0.90

      true ->
        valor_base * 0.70
    end
  end

  def bonificacion_dia(kilos_dia) when kilos_dia >= @kilos_bonificacion do
    @bonificacion_diaria
  end

  def bonificacion_dia(_kilos_dia) do
    0
  end

  def descuento_alimentacion(true, dias_trabajados) do
    dias_trabajados * @descuento_alimentacion
  end

  def descuento_alimentacion(false, _dias_trabajados) do
    0
  end

  def liquidar_recolectores(recolectores, pesajes_validos) do
    Enum.map(recolectores, fn recolector ->
      liquidar_recolector(recolector, pesajes_validos)
    end)
  end

  defp liquidar_recolector(recolector, pesajes_validos) do
    pesajes_recolector =
      Enum.filter(pesajes_validos, fn pesaje ->
        pesaje.recolector == recolector.codigo
      end)

    kilos =
      Enum.reduce(pesajes_recolector, 0, fn pesaje, acumulador ->
        acumulador + pesaje.kilos
      end)

    suma_pesajes =
      Enum.reduce(pesajes_recolector, 0, fn pesaje, acumulador ->
        acumulador + valor_pesaje(pesaje)
      end)

    pesajes_por_dia =
      Enum.group_by(pesajes_recolector, fn pesaje ->
        pesaje.dia
      end)

    bonificaciones =
      Map.values(pesajes_por_dia)
      |> Enum.reduce(0, fn pesajes_dia, acumulador ->
        kilos_dia =
          Enum.reduce(pesajes_dia, 0, fn pesaje, suma ->
            suma + pesaje.kilos
          end)

        acumulador + bonificacion_dia(kilos_dia)
      end)

    dias_trabajados =
      pesajes_por_dia
      |> Map.keys()
      |> length()

    alimentacion =
      descuento_alimentacion(
        recolector.alimentacion,
        dias_trabajados
      )

    bruto = suma_pesajes + bonificaciones
    neto = bruto - alimentacion

    %{
      codigo: recolector.codigo,
      nombre: recolector.nombre,
      kilos: kilos,
      pesajes: suma_pesajes,
      bonificaciones: bonificaciones,
      alimentacion: alimentacion,
      bruto: bruto,
      neto: neto,
      dias_trabajados: dias_trabajados
    }
  end
end
