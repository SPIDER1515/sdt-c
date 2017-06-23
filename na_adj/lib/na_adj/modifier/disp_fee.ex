defmodule NA.ADJ.Modifier.DispFee do

  def get_disp_fee(plan_info) do
    {_, lists} = get_disp_fee_by_id(plan_info.ppc.dispfee_modifier)
    lists
  end

  defp get_disp_fee_by_id(id) do
    NA.DB.Repo.Modifiers.get_disp_fee_by_id(id)
    |> verify_disp_fee
  end

  defp verify_disp_fee(nil) do
    IO.puts "disp_fee non existant"
    {:error, "60"}
  end

  defp verify_disp_fee(disp_fee) do
    disp_fee
  end

  def get_disp_fee_to_apply(disp_fee_list, cl_disp_fee) do
    zero = Decimal.new(0)
    case cl_disp_fee == zero do
      true -> Decimal.new(disp_fee_list.fee)
      false -> cl_disp_fee
    end
  end
 
end
