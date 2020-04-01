defmodule Despegar_app.WSTaxLogger do

    @moduledoc """
    Toma una url para get, una para post, el nombre de archivo a loguear y
    el numero de pagina (endpoint).
    Hace un HTTP request (get) obteniendo un JSON con array de clientes.
    Por cada cliente calcula impuestos, los informa mediantes HTTP request (post)
    y loguea en caso satisfactorio.
    Si surge error obteniendo los clientes, no procesa.
    Si surge error procesando un cliente, lo saltea.
    """

    defstruct get_url: "", post_url: "", file: "", page: 1, supervisor: WS_Spawner

    def run(ws = %Despegar_app.WSTaxLogger{}) do

        fetch_clients(ws)
        |>decode_clients
        |>make_taxes(ws)

    end

    def fetch_clients(ws = %Despegar_app.WSTaxLogger{}) do
        p = to_string(ws.page)
        HTTPoison.get(ws.get_url, [], params: %{page: p})
        |> handle_response
    end
    
    def handle_response(http_response) do
        case http_response do
            {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> {:ok, body}
            {:ok, %HTTPoison.Response{status_code: 404}} -> {:error, :not_found_404}
            {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
        end
    end

    def decode_clients({:ok, body}) do
        case Jason.decode(body) do
            {:ok, result} -> validate_clients(result)
            {:error, error} -> {:error, error}
        end
    end

    def decode_clients({:error, reason}) do
        {:error, reason}
    end

    def validate_clients(json) do
        case Map.get(json, "customers") do
            nil -> {:error, :atribute_error}
            clients_list -> {:ok, clients_list}
                
        end
    end

    def make_taxes({:ok, clients_list}, ws = %Despegar_app.WSTaxLogger{}) do
        
        processed = clients_list
        |> Stream.map(&Despegar_app.Client.from_json/1)
        |> Stream.filter(fn {a,_} -> a == :error end )
        |> Stream.map(fn {_a, c} -> report_tax(ws, c) end)
        |> Stream.filter(fn {a,_} -> a == :error end )
        |> Stream.each(fn c -> log_tax(ws, c) end)
        |> Enum.to_list
        |> length

        {:ok, processed}

    end

    def make_taxes({:error, reason}, _, _, _) do
        {:error, reason}
    end

    def report_tax(ws = %Despegar_app.WSTaxLogger{}, c = %Despegar_app.Client{}) do
        headers = [{"Content-type", "application/json"}]
        body = Despegar_app.Client.body_for_post(c)
        {r, _b} = HTTPoison.post(ws.post_url, body, headers, []) |> handle_response
        {r, c}
    end


    def log_tax(ws = %Despegar_app.WSTaxLogger{}, c = %Despegar_app.Client{}) do
        IO.write(ws.file, Despegar_app.Client.log_tex(c))
    end


end