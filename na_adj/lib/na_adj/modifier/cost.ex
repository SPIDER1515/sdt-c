defmodule NA.ADJ.Modifier.Cost do
  
  def get_cost(id) do
    NA.DB.Repo.Modifiers.get_cost_by_id(id)
    |> verify_cost
  end

  defp verify_cost(nil) do
    {:error, "69"}
  end

  defp verify_cost(cost) do
    cost
  end

  def get_cost_method_type([h | t]) do
    get_cost_method_type(t, h.cost_method_type) 
  end

  defp get_cost_method_type([h | t], cost_method_type) do
    case h.cost_method_type == cost_method_type do
      true -> get_cost_method_type(t, cost_method_type)
      _ -> {:error, "67"}
    end
  end

  defp get_cost_method_type([], cost_method_type) do
    case cost_method_type do
      "1" -> "lt"
      "2" -> "gt"
    end
  end

end
