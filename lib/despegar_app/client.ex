defmodule Despegar_app.Client do
    defstruct name: "", document: "", type: "HUMAN", amount: 0, date: ~D[2000-01-01], tax: 0.0, extraCharge: 0, legalAdvisor: "", extraTax: 0
    
    def complete_name(client = %Despegar_app.Client{type: "HUMAN"}) do
        client.name
    end

    def complete_name(client = %Despegar_app.Client{type: "ENTERPRISE"}) do
        client.name <> "," <> client.legalAdvisor
    end


    def calc_amount(client = %Despegar_app.Client{type: "HUMAN"}) do
        client.amount
    end

    def calc_amount(client = %Despegar_app.Client{type: "ENTERPRISE"}) do
        client.amount + client.extraCharge
    end


    def calc_tax(client = %Despegar_app.Client{type: "HUMAN"}) do
        calc_amount(client) * client.tax    
    end

    def calc_tax(client = %Despegar_app.Client{type: "ENTERPRISE"}) do
        client.amount * client.tax + client.extraCharge * client.extraTax
    end

    def body_for_post(client = %Despegar_app.Client{}) do
        Jason.encode!(%{
            "amount" => calc_amount(client),
            "total tax" => calc_tax(client),
            "name"=> complete_name(client),
            "document"=> client.document
            })
    end

    def log_tex(client = %Despegar_app.Client{}) do
        name = complete_name(client)
        amount = calc_amount(client) |> to_string
        tax = calc_tax(client) |> to_string
        name <> "," <> amount <> "," <> tax <> "\n"
    end

    def from_json(json) do
        case Map.get(json, "type") do
            nil -> {:error, :no_type_field}
            "HUMAN" -> from_json_person(json)
            "ENTERPRISE" -> from_json_legal_entity(json)
        end
    end

    def from_json_person(json) do
        error = ["name", "document", "amount", "date", "tax"]
        |> Enum.any?(fn e -> json |> Map.get(e) |> is_nil end)

        case error do
            true -> {:error, :field_error}
            false ->
                {:ok, %Despegar_app.Client{
                    name: Map.get(json, "name"),
                    document: Map.get(json, "document"),
                    amount: String.to_integer(Map.get(json, "amount")),
                    date: Date.from_iso8601!(Map.get(json, "date")),
                    tax: String.to_float(Map.get(json, "tax")),
                    type: Map.get(json, "type")
                    }
                }
        end
    end

    def from_json_legal_entity(json) do
        error = ["name", "document", "amount", "date", "tax", "extraCharge", "legalAdvisor", "extraTax"]
        |> Enum.any?(fn e -> json |> Map.get(e) |> is_nil end)

        case error do
            true -> {:error, :field_error}
            false -> 
                {:ok, %Despegar_app.Client{
                    name: Map.get(json, "name"),
                    document: Map.get(json, "document"),
                    amount: String.to_integer(Map.get(json, "amount")),
                    date: Date.from_iso8601!(Map.get(json, "date")),
                    tax: String.to_float(Map.get(json, "tax")),
                    type: Map.get(json, "type"),
                    extraTax: String.to_float(Map.get(json, "extraTax")),
                    extraCharge: String.to_integer(Map.get(json, "extraCharge")),
                    legalAdvisor: Map.get(json, "legalAdvisor")
                    }
                }
        end
    end

          
end