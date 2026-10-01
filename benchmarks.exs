# Integrantes: Laura, Mariana, Kebyn y Juan
# Este archivo corresponde a las mediciones adicionales pedidas por el profesor.


defmodule Benchmarks do
  def ejecutar_busquedas do
    recolectores =
      Enum.map(1..100_000, fn numero ->
        %{codigo: "R#{numero}", nombre: "Recolector #{numero}"}
      end)

    codigos =
      Enum.map(1..1_000, fn _numero ->
        "R#{:rand.uniform(100_000)}"
      end)

    mapa_recolectores =
      Enum.reduce(recolectores, %{}, fn recolector, acumulador ->
        Map.put(acumulador, recolector.codigo, recolector)
      end)

    {tiempo_lista, _resultado_lista} =
      :timer.tc(fn ->
        Enum.map(codigos, fn codigo ->
          Enum.find(recolectores, fn recolector ->
            recolector.codigo == codigo
          end)
        end)
      end)

    {tiempo_mapa, _resultado_mapa} =
      :timer.tc(fn ->
        Enum.map(codigos, fn codigo ->
          Map.get(mapa_recolectores, codigo)
        end)
      end)

    {tiempo_lista, tiempo_mapa}
  end

  def ejecutar_listas do
    {tiempo_final, _lista_final} =
      :timer.tc(fn ->
        Enum.reduce(1..20_000, [], fn elemento, lista ->
          lista ++ [elemento]
        end)
      end)

    {tiempo_inicio, _lista_inicio} =
      :timer.tc(fn ->
        Enum.reduce(1..20_000, [], fn elemento, lista ->
          [elemento | lista]
        end)
      end)

    {tiempo_final, tiempo_inicio}
  end
end

{lista_1, mapa_1} = Benchmarks.ejecutar_busquedas()
{lista_2, mapa_2} = Benchmarks.ejecutar_busquedas()
{lista_3, mapa_3} = Benchmarks.ejecutar_busquedas()

{final_1, inicio_1} = Benchmarks.ejecutar_listas()
{final_2, inicio_2} = Benchmarks.ejecutar_listas()
{final_3, inicio_3} = Benchmarks.ejecutar_listas()

Util.imprimir_mensaje("Búsqueda 1 - lista: #{lista_1} | mapa: #{mapa_1}")
Util.imprimir_mensaje("Búsqueda 2 - lista: #{lista_2} | mapa: #{mapa_2}")
Util.imprimir_mensaje("Búsqueda 3 - lista: #{lista_3} | mapa: #{mapa_3}")

Util.imprimir_mensaje("Lista 1 - final con ++: #{final_1} | inicio: #{inicio_1}")
Util.imprimir_mensaje("Lista 2 - final con ++: #{final_2} | inicio: #{inicio_2}")
Util.imprimir_mensaje("Lista 3 - final con ++: #{final_3} | inicio: #{inicio_3}")
