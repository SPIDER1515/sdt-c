defmodule NA.ADJ.Modifier.DispLimit do
  alias NA.DB.Repo.Modifiers, as: ModifiersRepo
  alias NA.Claims.ClaimAgent, as: Ca
  alias NA.Claims.ClaimField

  def get_disp_limit(pid, id, mony, maintenance, preferred) do
    get_disp_limit_lists(id)
    |> find_disp_limit_item(pid, mony, maintenance, preferred)
  end

  defp find_disp_limit_item(items, pid, mony, maintenance, preferred) do
    with {:ok, ds} <- get_ds(pid),
         {:ok, qty} <- get_qty(pid),
         {:ok, item} <- validate_items(items, mony, maintenance, preferred)
         do
          validate_matched_item(item, ds, qty)
    else
      rej -> rej
    end
  end

  defp get_ds(pid) do
    case Ca.find_claim_field(pid, "405", 1) do
      nil -> {:reject, "19"}
      %ClaimField{value: value} -> value
    end
  end

  defp get_qty(pid) do
    case Ca.find_claim_field(pid, "442", 1) do
      nil -> {:reject, "E7"}
      %ClaimField{value: value} -> value
    end
  end

  defp get_disp_limit_lists(id) do
    case ModifiersRepo.get_disp_limit_by_id(id) do
      nil -> nil
      {_, lists} -> lists
    end
  end

  def validate_items([], _mony, _preferred, _maintenance), do: nil
  def validate_items([%{mony: dl_mony} = h|t], mony, maintenance, preferred) do
    with true <- is_match_mony?(dl_mony, mony),
         %{} = item <- match_item(h, maintenance, preferred) 
         do
           item
    else
      _-> validate_items(t, mony, maintenance, preferred)
    end
  end
  
  defp match_item(%{auxiliary: "1"} = item, _maintenance, _preferred), do: item
  defp match_item(%{auxiliary: "2"} = item, false, true), do: item
  defp match_item(%{auxiliary: "3"} = item, true, false), do: item
  defp match_item(%{auxiliary: "4"} = item, true, true), do: item
  defp match_item(_item, _maintenance, _preferred), do: nil

  defp validate_matched_item(%{enforce_limits_type: "R"} = dl, _ds, _qty), do: dl
  defp validate_matched_item(%{enforce_limits_type: "N"} = dl, _ds, _qty), do: dl
  defp validate_matched_item(%{enforce_limits_type: "B"} = dl, ds, qty) do
    case is_within?(ds, dl.min_dayssupply, dl.max_dayssuply) 
    && is_within?(qty, dl.min_quantity, dl.max_quantity) do
       true -> dl
       false -> nil
    end
  end

  defp validate_matched_item(%{enforce_limits_type: "E"} = dl, ds, qty) do
    case is_within?(ds, dl.min_dayssupply, dl.max_dayssuply) 
    || is_within?(qty, dl.min_quantity, dl.max_quantity) do
       true -> dl
       false -> nil
    end
  end
  
  defp validate_matched_item(_dl, _ds, _qty), do: nil

  defp is_within?(than_val, min_val, max_val) do
    than_val >= min_val && than_val <= max_val
  end

  def is_match_mony?(mony_type, "N"), do: mony_type == "M"
  def is_match_mony?(mony_type, multi_source_code), do: mony_type == multi_source_code

end
