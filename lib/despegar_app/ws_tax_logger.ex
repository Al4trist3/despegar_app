defmodule Despegar_app.WSTaxLogger do

    def run(get_url, post_url, file_name) do
        fetch_clients(get_url, 1)
        |>decode_clients
        |>make_taxes(post_url, file_name)
    end


    def fetch_clients(get_url, page) do
        HTTPoison.get(get_url, [], params: %{page: "1"})
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

    def make_taxes({:ok, clients_list}, post_url, file_name) do
        path = Path.join(System.user_home!, file_name) 
        {:ok, file} = File.open(path,[:write, :utf8])
        
        clients_list
        |> Stream.filter(&validate_client/1)
        |> Stream.each(fn c -> report_tax(post_url,c) end)
        |> Stream.each(fn c -> log_tax(file, c) end)
        |> Enum.to_list

        File.close(file)
        
    end

    def make_taxes({:error, reason}, _, _) do
        {:error, reason}
    end

    def validate_client(client) do
        case Map.get(client, "type") do
            "HUMAN" -> validate_client_person(client)
            "ENTERPRISE" -> validate_client_legal_entity(client)
            nil -> false
        end
    end

    def validate_client_person(client) do
        fields = ["name", "document", "type", "amount", "date", "tax"]
        Enum.sort(fields) == Enum.sort(Map.keys(client))
    end

    def validate_client_legal_entity(client) do
        fields = ["name", "document", "type", "amount", "date", "tax", "extraCharge", "legalAdvisor", "extraTax"]
        Enum.sort(fields) == Enum.sort(Map.keys(client))
    end

    def calc_amount(client) do
        case Map.get(client, "type") do
            "HUMAN" -> Map.get(client, "amount") |> String.to_integer
            "ENTERPRISE" -> calc_amount_for_legal_entity(client)
        end
    end

    def calc_amount_for_legal_entity(client) do
        amount = Map.get(client, "amount") |> String.to_integer
        extra_charge = Map.get(client, "extraCharge") |> String.to_integer
        amount + extra_charge
    end

    def calc_tax(client) do
        case Map.get(client, "type") do
            "HUMAN" -> calc_tax_for_person(client)
            "ENTERPRISE" -> calc_amount_for_legal_entity(client)
        end
    end

    def calc_tax_for_person(client) do
        amount = calc_amount(client)
        tax = Map.get(client, "tax") |> String.to_float
        amount * tax
    end


    def calc_tax_for_legal_entity(client) do
        amount = Map.get(client, "amount") |> String.to_integer
        extra_charge = Map.get(client, "extraCharge") |> String.to_integer
        tax = Map.get(client, "tax") |> String.to_integer
        extra_tax = tax = Map.get(client, "extraTax") |> String.to_float
        amount * tax + extra_charge * extra_tax
    end

    def complete_name(client) do
        case Map.get(client, "type") do
            "HUMAN" -> Map.get(client, "name")
            "ENTERPRISE" -> Map.get(client, "name") <> "," <> Map.get(client, "legalAdvisor")
        end
    end


    def report_tax(post_url, client) do
        headers = [{"Content-type", "application/json"}]
        body = body_for_post(client)
        HTTPoison.post(post_url, body, headers, [])
    end

    def body_for_post(client) do
        Jason.encode!(%{
            "amount" => calc_amount(client),
            "total tax" => calc_tax(client),
            "name"=> complete_name(client),
            "document"=> Map.get(client, "document")
            })
    end

    def log_tax(file, client) do
        name = complete_name(client)
        amount = calc_amount(client) |> to_string
        tax = calc_tax(client) |> to_string
        log_tex = name <> "," <> amount <> "," <> tax <> "\n"
        IO.write(file, log_tex)
    end


end