defmodule Despegar_app.CLI do
    @default_file_name "despegarLog.txt"

    @moduledoc """
    Maneja los argumentos de la linea de comandos
    y deriva a las funciones que terminan generando el
    cobro de impuestos y logueo de las operaciones
    """

    def run(argv) do
        argv 
            |> parse_args
            |> Benchmark.measure(&process/1)
    end


    @doc """
    'argv' puede ser -h o -help que retorna :help.
    Si no, es las urls para obtener los clientes y
    informar el cobro de impuestos y el nombre del 
    archivo para loggear.
    Devuelve una tupla de '{get_url, post_url, file_name}',
    o ':help'
    """

    def parse_args(argv) do
        parse = OptionParser.parse(argv, switches: [help: :boolean], aliases: [h: :help])

        case parse do
            {[help: true], _, _} -> :help
            {_, [get_url, post_url, file_name], _} -> {get_url, post_url, file_name}
            {_, [get_url, post_url], _} -> {get_url, post_url, @default_file_name}
            _ -> :help
                
        end
    end

    def process(:help) do
        IO.puts "Uso: despegar_app <get_url> <post_url> [file_name | #{@default_file_name}]"
        System.halt(0)
    end

    def process({get_url, post_url, file_name}) do
        WS_Spawner.generate(get_url, post_url, file_name)
    end



end