defmodule NA.Adj.PharmacyPanel do

  def get_pharmacy_panel_item(pharmacy_panel_id, nabp, chain_code, rx_date) do
    { _, pharmacy_panel_tree} = NA.DB.Repo.PharmacyPanel.get_by_id(pharmacy_panel_id)
    find_matched_pharmacy_panel_item(pharmacy_panel_tree, nabp, chain_code, rx_date)
  end

  def find_matched_pharmacy_panel_item(pharmacy_panel_items, nabp, chain_code, rx_date) do
    case match_pharmacy_panel_item(pharmacy_panel_items, nabp, chain_code, rx_date) do
      :exclude -> nil
      nil -> nil
      %{} = p -> p
    end
  end

  def match_pharmacy_panel_item([], _, _, _) do
    nil
  end

  def match_pharmacy_panel_item([%{panel_list_type: "N", inc_type: "E", items: items} = h | t], nabp, chain, rx_date) do
    case NA.Shared.Date.date_is_active(rx_date, h.start_date, h.end_date) do
      false -> find_matched_pharmacy_panel_item(t, nabp, chain, rx_date)
      true -> case find_matched_pharmacy_panel_item(items, nabp, chain, rx_date) do
                %{} -> :exclude
                _ -> find_matched_pharmacy_panel_item(t, nabp, chain, rx_date)
              end
    end
  end

  def match_pharmacy_panel_item([%{panel_list_type: "N", inc_type: "I", items: items} = h | t], nabp, chain, rx_date) do
    case NA.Shared.Date.date_is_active(rx_date, h.start_date, h.end_date) do
      false -> find_matched_pharmacy_panel_item(t, nabp, chain, rx_date)
      true -> find_matched_pharmacy_panel_item(items, nabp, chain, rx_date)
    end
    |> case do
        nil -> find_matched_pharmacy_panel_item(t, nabp, chain, rx_date)
        %{} = p -> p
      end
  end

  def match_pharmacy_panel_item([%{inc_type: "E"} = h | t], nabp, chain, rx_date) do
    case match_item(h, nabp, chain, rx_date) do
      true -> :exclude 
      false -> match_pharmacy_panel_item(t, nabp, chain, rx_date)
    end
  end

  def match_pharmacy_panel_item([%{inc_type: "I"} = h | t], nabp, chain, rx_date) do
    case match_item(h, nabp, chain, rx_date) do
      true -> h
      false -> match_pharmacy_panel_item(t, nabp, chain, rx_date)
    end
  end

  def match_item(%{panel_list_type: "P", nabp: nil}, _nabp, _chain, _rx_date), do: false
  
  def match_item(%{panel_list_type: "P", chain: nil, nabp: pp_nabp} = item, nabp, _chain, rx_date) when nabp == pp_nabp do
    NA.Shared.Date.date_is_active(rx_date, item.start_date, item.end_date)
  end
  
  def match_item(%{panel_list_type: "P", chain: nil, nabp: pp_nabp} = item, nabp, _chain, rx_date) do
    base = byte_size(pp_nabp)-1
    <<h::binary-size(base), last::binary>> = pp_nabp
    match = 
      case last do
        "*" -> String.starts_with?(nabp, h) 
        _ -> pp_nabp === nabp
      end
    match && NA.Shared.Date.date_is_active(rx_date, item.start_date, item.end_date)
  end

  def match_item(%{panel_list_type: "P", chain: pp_chain, nabp: pp_nabp} = item, nabp, chain, rx_date) when chain  == pp_chain do
    base = byte_size(pp_nabp)-1
    <<h::binary-size(base), "*"::binary>> = pp_nabp
    String.starts_with?(nabp, h) && NA.Shared.Date.date_is_active(rx_date, item.start_date, item.end_date)
  end

  def match_item(%{panel_list_type: "C", chain: pp_chain, state_code: nil}, _nabp, chain, _rx_date) do
    chain == pp_chain
  end

  def match_item(%{panel_list_type: "C", chain: pp_chain, state_code: state_code}, nabp, chain, _rx_date) do
    chain == pp_chain && String.starts_with?(nabp, state_code)
  end
  
  def match_item(_item, _nabp, _chain, _rx_date) do
    false
  end
  
end
