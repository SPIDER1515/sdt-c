defmodule NA.ADJ.Pharmacy do
  
  alias NA.DB.Repo.Pharmacy, as: PharmacyRepo
  alias NA.Shared.Date

  def get_by_nabp(nabp, rx_date) do
    PharmacyRepo.get_by_nabp(nabp)
    |> verify_pharmacy
    |> match_pharmacy_info(rx_date)
  end 

  def get_by_npi(npi, rx_date) do
    PharmacyRepo.get_by_npi(npi)
    |> verify_pharmacy
    |> match_pharmacy_info(rx_date)
  end 

  defp verify_pharmacy([]), do: {:error, "61"}
  defp verify_pharmacy(pharmacy), do: pharmacy

  def match_pharmacy_info({:error, _rej} = rej, _rx_date), do: rej
  def match_pharmacy_info({pharmacy, aff_list, addr_list}, rx_date) do
    al_code = match_affiliation_list(aff_list, rx_date)
    address = match_address_list(addr_list)

    Map.put(pharmacy, :affiliation_list, al_code)
    |> Map.put(:address, address)
  end

  defp match_affiliation_list([], _rx_date), do: nil
  defp match_affiliation_list([%{start_date: sd, end_date: ed} = h | t], rx_date) do
    case Date.date_is_active(rx_date, sd, ed) do
      true -> h
      false -> match_affiliation_list(t, rx_date)
    end
  end

  defp match_address_list([]), do: nil
  defp match_address_list([%{type: "1"} = item | _]), do: item
  defp match_address_list([_| t]) do
    match_address_list(t)
  end
  
end
