# Integrantes: Laura, Mariana, Kebyn y Juan

defmodule Programa do
  @moduledoc """
  Función principal que coordina la carga, validación, liquidación y reportes.
  """

  def main do
    recolectores = Datos.recolectores()
    lotes = Datos.lotes()
    pesajes = Datos.pesajes()

    recolectores_por_codigo =
      Colecciones.recolectores_por_codigo(recolectores)

    lotes_por_id =
      Colecciones.lotes_por_id(lotes)

    {pesajes_validos, pesajes_rechazados} =
      Validacion.separar_pesajes(
        pesajes,
        recolectores_por_codigo,
        lotes_por_id
      )

    linea_adicional =
      Util.leer(
        "Ingrese un pesaje adicional (recolector;lote;dia;kilos;verdes) o Enter para omitir: ",
        :string
      )

    {pesajes_validos, mensaje_adicional} =
      procesar_pesaje_adicional(
        linea_adicional,
        pesajes_validos,
        recolectores_por_codigo,
        lotes_por_id
      )

    Util.imprimir_mensaje(mensaje_adicional)
    Util.imprimir_mensaje("")

    liquidaciones =
      Liquidacion.liquidar_recolectores(
        recolectores,
        pesajes_validos
      )

    Util.imprimir_mensaje(Reportes.r1(pesajes_rechazados))
    Util.imprimir_mensaje("")
    Util.imprimir_mensaje(Reportes.r2(lotes, pesajes_validos))
    Util.imprimir_mensaje("")
    Util.imprimir_mensaje(Reportes.r3(pesajes_validos))
    Util.imprimir_mensaje("")
    Util.imprimir_mensaje(Reportes.r4(liquidaciones))
    Util.imprimir_mensaje("")
    Util.imprimir_mensaje(
      Reportes.r5(
        recolectores_por_codigo,
        pesajes_validos
      )
    )

    Util.imprimir_mensaje("")
    Util.imprimir_mensaje(
      Reportes.r6(
        recolectores_por_codigo,
        pesajes_validos
      )
    )

    Util.imprimir_mensaje("")
    Util.imprimir_mensaje(
      Reportes.r7(
        liquidaciones,
        pesajes_validos
      )
    )

    Util.imprimir_mensaje("")
    Util.imprimir_mensaje(
      Reportes.r8(
        recolectores,
        lotes,
        pesajes_validos
      )
    )

    Util.imprimir_mensaje("")
    Util.imprimir_mensaje("C1. Ranking con opciones")
    Util.imprimir_mensaje(Reportes.ranking(liquidaciones, []))
    Util.imprimir_mensaje("")
    Util.imprimir_mensaje(
      Reportes.ranking(
        liquidaciones,
        campo: :kilos,
        limite: 3
      )
    )

    Util.imprimir_mensaje("")
    Util.imprimir_mensaje(
      Reportes.ranking(
        liquidaciones,
        orden: :asc,
        campo: :bruto
      )
    )

    mapa_finca =
      Reportes.kilos_por_dia(pesajes_validos)

    finca_vecina = %{
      1 => 520.5,
      2 => 610,
      3 => 480,
      5 => 700,
      7 => 300
    }

    mapa_combinado =
      Reportes.combinar_fincas(
        mapa_finca,
        finca_vecina
      )

    Util.imprimir_mensaje("")
    Util.imprimir_mensaje("C2. Producción combinada de las dos fincas")
    Util.imprimir_mensaje(
      Reportes.mapa_dias_a_texto(
        mapa_combinado
      )
    )

    Util.imprimir_mensaje("")

    codigo =
      Util.leer(
        "Ingrese el código del recolector para ver su desprendible: ",
        :string
      )

    Util.imprimir_mensaje(
      Reportes.desprendible(
        codigo,
        recolectores_por_codigo,
        pesajes_validos,
        liquidaciones
      )
    )
  end

  defp procesar_pesaje_adicional(
         "",
         pesajes_validos,
         _recolectores_por_codigo,
         _lotes_por_id
       ) do
    {pesajes_validos, "No se agregó ningún pesaje."}
  end

  defp procesar_pesaje_adicional(
         linea,
         pesajes_validos,
         recolectores_por_codigo,
         lotes_por_id
       ) do
    case Validacion.convertir_linea_pesaje(linea) do
      {:error, motivo} ->
        {pesajes_validos, "Pesaje rechazado: #{motivo}"}

      {:ok, pesaje} ->
        case Validacion.validar_pesaje(
               pesaje,
               recolectores_por_codigo,
               lotes_por_id
             ) do
          {:ok, pesaje_valido} ->
            nuevos_pesajes =
              pesajes_validos ++ [pesaje_valido]

            mensaje =
              "Pesaje agregado: #{pesaje_valido.recolector} en #{pesaje_valido.lote}, " <>
                "día #{pesaje_valido.dia}, #{pesaje_valido.kilos} kg, " <>
                "#{pesaje_valido.verdes} % de verdes."

            {nuevos_pesajes, mensaje}

          {:error, motivo} ->
            {pesajes_validos, "Pesaje rechazado: #{motivo}"}
        end
    end
  end
end

Programa.main()
