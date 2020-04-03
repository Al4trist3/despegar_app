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

    def extract_type(%{"type" => type}), do: {:ok, type}
    def extract_type(_), do: {:error, :type_missing}

    def extract_name(%{"name" => name}), do: {:ok, name}
    def extract_name(_), do: {:error, :name_missing}

    def extract_document(%{"document" => document}), do: {:ok, String.to_integer(document)}
    def extract_document(_), do: {:error, :document_missing}
    
    def extract_amount(%{"amount" => amount}), do: {:ok, String.to_integer(amount)}
    def extract_amount(_), do: {:error, :amount_missing}

    def extract_date(%{"date" => date}), do: {:ok, Date.from_iso8601!(date)}
    def extract_date(_), do: {:error, :date_missing}

    def extract_tax(%{"tax" => tax}), do: {:ok, String.to_float(tax)}
    def extract_tax(_), do: {:error, :tax_missing}

    def extract_extra_charge(%{"extraCharge" => extra_charge}), do: {:ok, String.to_integer(extra_charge)}
    def extract_extra_charge(_), do: {:error, :extra_charge_missing}

    def extract_legal_advisor(%{"legalAdvisor" => legal_advisor}), do: {:ok, legal_advisor}
    def extract_legal_advisor(_), do: {:error, :legal_advisor_missing}

    def extract_extra_tax(%{"extraTax" => extra_tax}), do: {:ok, String.to_float(extra_tax)}
    def extract_extra_tax(_), do: {:error, :extra_tax_missing}

    def from_json(json) do
        case extract_type(json) do
            {:error, reason} -> {:error, reason}
            {:ok, "HUMAN"} -> from_json_person(json)
            {:ok, "ENTERPRISE"} -> from_json_legal_entity(json)
        end
    end

    def from_json_person(json) do
        with {:ok, name} <- extract_name(json),
            {:ok, document} <- extract_document(json),
            {:ok, amount} <- extract_amount(json),
            {:ok, date} <- extract_date(json),
            {:ok, tax} <- extract_tax(json) do
                {:ok, %Despegar_app.Client{
                    name: name,
                    document: document,
                    amount: amount,
                    date: date,
                    tax: tax,
                    type: "HUMAN"
                    }
                }
            end
    end

    def from_json_legal_entity(json) do
        with {:ok, name} <- extract_name(json),
            {:ok, document} <- extract_document(json),
            {:ok, amount} <- extract_amount(json),
            {:ok, date} <- extract_date(json),
            {:ok, tax} <- extract_tax(json),
            {:ok, extra_charge} <- extract_extra_charge(json),
            {:ok, extra_tax} <- extract_extra_tax(json),
            {:ok, legal_advisor} <- extract_legal_advisor(json) do
                {:ok, %Despegar_app.Client{
                    name: name,
                    document: document,
                    amount: amount,
                    date: date,
                    tax: tax,
                    type: "ENTERPRISE",
                    extraTax: extra_tax,
                    extraCharge: extra_charge,
                    legalAdvisor: legal_advisor
                    }
                }
            end
    end
          
end