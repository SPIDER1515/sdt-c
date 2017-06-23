defmodule NA.Adj.Prescriber.Panel do
  
  alias  NA.Shared.Date, as: Date
  alias NA.DB.Repo.PrescriberPanel, as: PP

  def get_prescriber_panel(id, rx_date, npi, dea) do
    {p, ppi} = PP.get_by_id(id) 
    match_ppi = match_prescriber_panel_items(ppi, rx_date, npi, dea)
    {p, ppi, match_ppi}
  end

  def match_prescriber_panel_items(items, rx_date, npi, dea) do
    Enum.find(items, fn (i) -> 
      Date.date_is_active(rx_date, i.start_date, i.end_date) &&
        match_item?(i, npi,dea) 
    end)
  end

  def match_item?(i, npi, dea) do
    case i.panel_list_type do
      "P" -> i.npi == npi
      _ -> i.dea == dea
    end
  end
end
