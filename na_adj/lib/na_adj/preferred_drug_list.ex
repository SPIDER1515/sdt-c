defmodule NA.ADJ.PreferredDrugList do 
  alias NA.Shared.Date

  def find_preferred_drug_list(pdl_id, drug, rx_date) do
    get_preferred_drug_list_items(pdl_id)
    |> match_pdl_drug(drug, rx_date)
  end
  
  defp get_preferred_drug_list_items(id) do
    {_, items} = get_preferred_drug_list_by_id(id)

    items
  end

  defp get_preferred_drug_list_by_id(id)do
    NA.DB.Repo.PreferredDrugList.get_by_id(id)
    |> verify_pdl
  end

  defp verify_pdl(nil), do: nil 
  defp verify_pdl([]), do: nil
  defp verify_pdl(pdl), do: pdl

  def match_pdl_drug(nil, _drug, _rx_date), do: :no_list 
  def match_pdl_drug([], _drug, _rx_date), do: :no_match
  def match_pdl_drug([h|t], drug, rx_date) do
    with true <- Date.date_is_active(rx_date, h.start_date, h.end_date) do
      case match_item(h, drug) do
        nil -> match_pdl_drug(t, drug, rx_date)
        %{} = pdl -> pdl
      end
    else 
      _ -> match_item(t, drug)
    end
  end

  defp match_item(%{type: "N", value: value} = item, %{ndc_upc_hri: ndc}) when ndc == value do
    item
  end

  defp match_item(%{type: "G", value: value} = item, %{gpi: gpi}) when gpi == value do
    item
  end

  defp match_item(_item, _drug), do: nil
end
