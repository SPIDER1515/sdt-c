defmodule NA.ADJ.Drug do 
  alias NA.Shared.Date
  alias NA.DB.Repo.Drug, as: DrugRepo

  def get_drug(ndc, rx_date)do
    DrugRepo.get_by_ndc(ndc)
    |> verify_drug
    |> find_effective_price(rx_date)
  end

  defp verify_drug(nil), do: {:error, "54"}
  defp verify_drug({_d, []}), do: {:error,"56"}
  defp verify_drug({%{drug_status: "D"}, _prices}), do: {:error, "77"}
  defp verify_drug({%{drug_status: "U"}, _prices}), do: {:error, "54"}
  defp verify_drug({_, _} = dr), do: dr

  def find_effective_price({:error, _rej} = rej, _rx_date), do: rej
  def find_effective_price({_, prices} = drug_info, rx_date) do
    with %{} = eff_price <- match_price(prices, rx_date) do
      %{effective_price: eff_price, drug: drug_info}
    else 
      rslt -> rslt
    end
  end

  defp match_price([], _rx_date), do: {:error, "95"}
  defp match_price([h|t], rx_date) do
    case match_item(h, rx_date) do 
      %{} = item -> item
      _ -> match_price(t, rx_date)
    end
  end

  defp match_item(%{price_code: "A", price_effective_date: eff_date} = item, rx_date) do
    case Date.greater_than(rx_date, eff_date) do
      true -> item
      _ -> nil
    end
  end
  
  defp match_item(_item, _rx_date), do: nil

end
