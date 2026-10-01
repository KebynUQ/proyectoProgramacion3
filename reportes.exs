# Integrantes: Laura, Mariana, Kebyn y Juan

defmodule Reportes do
  @moduledoc """
  Construye los textos de los reportes sin imprimirlos.
  """

  @meta_diaria 400
  @dias_cosecha 6

  @motivos [
    :recolector_desconocido,
    :lote_desconocido,
    :dia_invalido,
    :kilos_fuera_de_rango,
    :porcentaje_invalido
  ]

  def r1(rechazados) do
    detalle =
      rechazados
      |> Enum.map(fn {pesaje, motivo} ->
        "#{pesaje.recolector} | #{pesaje.lote} | día #{pesaje.dia} | " <>
          "#{pesaje.kilos} kg | #{pesaje.verdes} % -> #{motivo}"
      end)
      |> Enum.join("\n")

    conteos =
      Enum.frequencies_by(rechazados, fn {_pesaje, motivo} ->
        motivo
      end)

    resumen =
      @motivos
      |> Enum.map(fn motivo ->
        cantidad = Map.get(conteos, motivo) || 0
        "#{motivo}: #{cantidad}"
      end)
      |> Enum.join("\n")

    "R1. Pesajes rechazados\n" <>
      detalle <>
      "\nRechazos por motivo\n" <>
      resumen
  end

  def r2(lotes, pesajes_validos) do
    resultados =
      Enum.map(lotes, fn lote ->
        kilos =
          pesajes_validos
          |> Enum.filter(fn pesaje -> pesaje.lote == lote.id end)
          |> Enum.reduce(0, fn pesaje, acumulador ->
            acumulador + pesaje.kilos
          end)

        rendimiento =
          if lote.hectareas == 0 do
            0
          else
            kilos / lote.hectareas
          end

        %{
          nombre: lote.nombre,
          kilos: kilos,
          hectareas: lote.hectareas,
          rendimiento: rendimiento
        }
      end)
      |> Enum.sort_by(fn resultado -> resultado.rendimiento end, :desc)

    lineas =
      resultados
      |> Enum.map(fn resultado ->
        "#{resultado.nombre} | #{resultado.kilos} kg | " <>
          "#{resultado.hectareas} ha | " <>
          "#{formatear_decimal(resultado.rendimiento)} kg/ha"
      end)
      |> Enum.join("\n")

    "R2. Kilos por lote\n" <> lineas
  end

  def kilos_por_dia(pesajes_validos) do
    Enum.reduce(1..@dias_cosecha, %{}, fn dia, acumulador ->
      kilos =
        pesajes_validos
        |> Enum.filter(fn pesaje -> pesaje.dia == dia end)
        |> Enum.reduce(0, fn pesaje, suma ->
          suma + pesaje.kilos
        end)

      Map.put(acumulador, dia, kilos)
    end)
  end

  def r3(pesajes_validos) do
    mapa_dias = kilos_por_dia(pesajes_validos)

    lineas =
      1..@dias_cosecha
      |> Enum.map(fn dia ->
        kilos = Map.get(mapa_dias, dia)

        "#{linea_dia_meta(dia, kilos)}"
      end)
      |> Enum.join("\n")

    cumplio_todos =
      Enum.all?(1..@dias_cosecha, fn dia ->
        Map.get(mapa_dias, dia) >= @meta_diaria
      end)

    cumplio_alguno =
      Enum.any?(1..@dias_cosecha, fn dia ->
        Map.get(mapa_dias, dia) >= @meta_diaria
      end)

    "R3. Kilos por día (meta: #{@meta_diaria} kg)\n" <>
      lineas <>
      "\n¿Se cumplió la meta todos los días? #{texto_si_no(cumplio_todos)}" <>
      "\n¿Se cumplió la meta al menos un día? #{texto_si_no(cumplio_alguno)}"
  end

  def r4(liquidaciones) do
    lineas =
      liquidaciones
      |> Enum.sort_by(fn liquidacion -> liquidacion.neto end, :desc)
      |> Enum.with_index()
      |> Enum.map(fn {liquidacion, indice} ->
        "#{indice + 1}. | #{liquidacion.nombre} | #{liquidacion.kilos} kg | " <>
          "$#{formatear_pesos(liquidacion.pesajes)} | " <>
          "$#{formatear_pesos(liquidacion.bonificaciones)} | " <>
          "$#{formatear_pesos(liquidacion.alimentacion)} | " <>
          "$#{formatear_pesos(liquidacion.neto)}"
      end)
      |> Enum.join("\n")

    "R4. Liquidación de la semana\n" <>
      "# | Recolector | Kilos | Pesajes | Bonificaciones | Alimentación | Neto\n" <>
      lineas
  end

  def r5(recolectores_por_codigo, pesajes_validos) do
    resultados =
      Enum.map(1..@dias_cosecha, fn dia ->
        mejores_del_dia(dia, pesajes_validos)
      end)

    lineas =
      resultados
      |> Enum.map(fn resultado ->
        linea_mejor_dia(resultado, recolectores_por_codigo)
      end)
      |> Enum.join("\n")

    conteo_mejores =
      Enum.reduce(resultados, %{}, fn resultado, acumulador ->
        Enum.reduce(resultado.mejores, acumulador, fn codigo, mapa ->
          Map.update(mapa, codigo, 1, fn cantidad ->
            cantidad + 1
          end)
        end)
      end)

    resumen_final =
      if Map.keys(conteo_mejores) == [] do
        "Más días como mejor recolector: no hubo pesajes válidos"
      else
        mayor_cantidad =
          Map.values(conteo_mejores)
          |> Enum.max_by(fn cantidad -> cantidad end)

        codigos =
          Map.keys(conteo_mejores)
          |> Enum.filter(fn codigo ->
            Map.get(conteo_mejores, codigo) == mayor_cantidad
          end)
          |> Enum.sort_by(fn codigo -> codigo end, :asc)

        nombres =
          codigos
          |> Enum.map(fn codigo ->
            nombre_recolector(recolectores_por_codigo, codigo)
          end)
          |> Enum.join(", ")

        "Más días como mejor recolector: #{nombres} (#{mayor_cantidad} días)"
      end

    "R5. Mejor recolector de cada día\n" <>
      lineas <>
      "\n" <>
      resumen_final
  end

  def r6(recolectores_por_codigo, pesajes_validos) do
    candidatos =
      pesajes_validos
      |> Enum.group_by(fn pesaje -> pesaje.recolector end)
      |> Enum.filter(fn {_codigo, pesajes} ->
        length(pesajes) >= 3
      end)
      |> Enum.map(fn {codigo, pesajes} ->
        suma_ponderada =
          Enum.reduce(pesajes, 0, fn pesaje, acumulador ->
            acumulador + pesaje.verdes * pesaje.kilos
          end)

        kilos =
          Enum.reduce(pesajes, 0, fn pesaje, acumulador ->
            acumulador + pesaje.kilos
          end)

        %{
          codigo: codigo,
          porcentaje: suma_ponderada / kilos
        }
      end)

    if candidatos == [] do
      "R6. Mejor calidad (mínimo 3 pesajes válidos)\nNo hay recolectores que cumplan el mínimo."
    else
      mejor =
        Enum.min_by(candidatos, fn candidato ->
          candidato.porcentaje
        end)

      nombre =
        nombre_recolector(
          recolectores_por_codigo,
          mejor.codigo
        )

      "R6. Mejor calidad (mínimo 3 pesajes válidos)\n" <>
        "#{nombre}, con #{formatear_decimal(mejor.porcentaje)} % de verdes ponderado por kilos"
    end
  end

  def r7(liquidaciones, pesajes_validos) do
    total_pagado =
      Enum.reduce(liquidaciones, 0, fn liquidacion, acumulador ->
        acumulador + liquidacion.neto
      end)

    kilos_validos =
      Enum.reduce(pesajes_validos, 0, fn pesaje, acumulador ->
        acumulador + pesaje.kilos
      end)

    costo_promedio =
      if kilos_validos == 0 do
        0
      else
        total_pagado / kilos_validos
      end

    "R7. Totales de la semana\n" <>
      "Total a pagar: $#{formatear_pesos(total_pagado)}\n" <>
      "Kilos válidos: #{kilos_validos} kg\n" <>
      "Costo promedio por kilo: $#{formatear_pesos(costo_promedio)}"
  end

  def r8(recolectores, lotes, pesajes_validos) do
    ids_lotes =
      Enum.map(lotes, fn lote ->
        lote.id
      end)

    recolectores_cumplen =
      Enum.filter(recolectores, fn recolector ->
        lotes_recolector =
          pesajes_validos
          |> Enum.filter(fn pesaje ->
            pesaje.recolector == recolector.codigo
          end)
          |> Enum.map(fn pesaje -> pesaje.lote end)
          |> Enum.uniq()

        Enum.all?(ids_lotes, fn id_lote ->
          Enum.any?(lotes_recolector, fn lote ->
            lote == id_lote
          end)
        end)
      end)

    if recolectores_cumplen == [] do
      "R8. Recolectores que trabajaron en todos los lotes\nNo hay recolectores que hayan trabajado en todos los lotes."
    else
      nombres =
        recolectores_cumplen
        |> Enum.map(fn recolector -> recolector.nombre end)
        |> Enum.join("\n")

      "R8. Recolectores que trabajaron en todos los lotes\n" <> nombres
    end
  end

  def ranking(liquidaciones, opciones) do
    campo = Keyword.get(opciones, :campo, :neto)
    orden = Keyword.get(opciones, :orden, :desc)
    limite = Keyword.get(opciones, :limite, length(liquidaciones))

    lineas =
      liquidaciones
      |> Enum.sort_by(fn liquidacion ->
        valor_campo(liquidacion, campo)
      end, orden)
      |> Enum.take(limite)
      |> Enum.with_index()
      |> Enum.map(fn {liquidacion, indice} ->
        "#{indice + 1}. #{liquidacion.nombre} | " <>
          "#{campo}: #{mostrar_valor_ranking(liquidacion, campo)}"
      end)
      |> Enum.join("\n")

    "Ranking por #{campo} (#{orden})\n" <> lineas
  end

  def combinar_fincas(mapa_finca, mapa_vecina) do
    Map.merge(mapa_finca, mapa_vecina, fn _dia, kilos_finca, kilos_vecina ->
      kilos_finca + kilos_vecina
    end)
  end

  def mapa_dias_a_texto(mapa_dias) do
    mapa_dias
    |> Map.keys()
    |> Enum.sort_by(fn dia -> dia end, :asc)
    |> Enum.map(fn dia ->
      "Día #{dia}: #{Map.get(mapa_dias, dia)} kg"
    end)
    |> Enum.join("\n")
  end

  def desprendible(
        codigo,
        recolectores_por_codigo,
        pesajes_validos,
        liquidaciones
      ) do
    recolector = Map.get(recolectores_por_codigo, codigo)

    if recolector == nil do
      "No existe un recolector con el código #{codigo}."
    else
      liquidacion =
        Enum.find(liquidaciones, fn item ->
          item.codigo == codigo
        end)

      pesajes_recolector =
        Enum.filter(pesajes_validos, fn pesaje ->
          pesaje.recolector == codigo
        end)

      pesajes_por_dia =
        Enum.group_by(pesajes_recolector, fn pesaje ->
          pesaje.dia
        end)

      detalle =
        pesajes_por_dia
        |> Map.keys()
        |> Enum.sort_by(fn dia -> dia end, :asc)
        |> Enum.map(fn dia ->
          pesajes_dia = Map.get(pesajes_por_dia, dia)

          kilos =
            Enum.reduce(pesajes_dia, 0, fn pesaje, acumulador ->
              acumulador + pesaje.kilos
            end)

          valor_dia =
            Enum.reduce(pesajes_dia, 0, fn pesaje, acumulador ->
              acumulador + Liquidacion.valor_pesaje(pesaje)
            end)

          bonificacion =
            Liquidacion.bonificacion_dia(kilos)

          "Día #{dia}: #{kilos} kg | " <>
            "pesajes $#{formatear_pesos(valor_dia)} | " <>
            "bonificación $#{formatear_pesos(bonificacion)}"
        end)
        |> Enum.join("\n")

      "Desprendible de pago - #{recolector.nombre} (#{recolector.codigo})\n" <>
        detalle <>
        "\nSuma de pesajes: $#{formatear_pesos(liquidacion.pesajes)}" <>
        "\nBonificaciones: $#{formatear_pesos(liquidacion.bonificaciones)}" <>
        "\nAlimentación (#{liquidacion.dias_trabajados} días): -$#{formatear_pesos(liquidacion.alimentacion)}" <>
        "\nNeto a pagar: $#{formatear_pesos(liquidacion.neto)}"
    end
  end

  defp linea_dia_meta(dia, kilos) do
    if kilos >= @meta_diaria do
      "Día #{dia}: #{kilos} kg -> cumplió la meta"
    else
      "Día #{dia}: #{kilos} kg -> no cumplió la meta"
    end
  end

  defp texto_si_no(true), do: "Sí"
  defp texto_si_no(false), do: "No"

  defp mejores_del_dia(dia, pesajes_validos) do
    pesajes_dia =
      Enum.filter(pesajes_validos, fn pesaje ->
        pesaje.dia == dia
      end)

    if pesajes_dia == [] do
      %{dia: dia, kilos: 0, mejores: []}
    else
      totales =
        pesajes_dia
        |> Enum.group_by(fn pesaje ->
          pesaje.recolector
        end)
        |> Enum.map(fn {codigo, pesajes} ->
          kilos =
            Enum.reduce(pesajes, 0, fn pesaje, acumulador ->
              acumulador + pesaje.kilos
            end)

          %{codigo: codigo, kilos: kilos}
        end)

      mayor =
        Enum.max_by(totales, fn total ->
          total.kilos
        end)

      mejores =
        totales
        |> Enum.filter(fn total ->
          total.kilos == mayor.kilos
        end)
        |> Enum.map(fn total -> total.codigo end)
        |> Enum.sort_by(fn codigo -> codigo end, :asc)

      %{
        dia: dia,
        kilos: mayor.kilos,
        mejores: mejores
      }
    end
  end

  defp linea_mejor_dia(resultado, recolectores_por_codigo) do
    if resultado.mejores == [] do
      "Día #{resultado.dia}: sin pesajes"
    else
      nombres =
        resultado.mejores
        |> Enum.map(fn codigo ->
          nombre_recolector(recolectores_por_codigo, codigo)
        end)
        |> Enum.join(", ")

      "Día #{resultado.dia}: #{nombres} (#{resultado.kilos} kg)"
    end
  end

  defp nombre_recolector(recolectores_por_codigo, codigo) do
    recolector = Map.get(recolectores_por_codigo, codigo)

    if recolector == nil do
      codigo
    else
      recolector.nombre
    end
  end

  defp valor_campo(liquidacion, :kilos), do: liquidacion.kilos
  defp valor_campo(liquidacion, :bruto), do: liquidacion.bruto
  defp valor_campo(liquidacion, :neto), do: liquidacion.neto
  defp valor_campo(liquidacion, _campo), do: liquidacion.neto

  defp mostrar_valor_ranking(liquidacion, :kilos) do
    "#{liquidacion.kilos} kg"
  end

  defp mostrar_valor_ranking(liquidacion, :bruto) do
    "$#{formatear_pesos(liquidacion.bruto)}"
  end

  defp mostrar_valor_ranking(liquidacion, :neto) do
    "$#{formatear_pesos(liquidacion.neto)}"
  end

  defp mostrar_valor_ranking(liquidacion, _campo) do
    "$#{formatear_pesos(liquidacion.neto)}"
  end

  defp formatear_pesos(valor) do
    :erlang.float_to_binary(valor * 1.0, decimals: 2)
  end

  defp formatear_decimal(valor) do
    :erlang.float_to_binary(valor * 1.0, decimals: 2)
  end
end
