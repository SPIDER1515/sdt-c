defmodule NA.ADJ.Plan.BenefitList do

  def get_benefit_list_list(plan_id, rx_date) do
    NA.DB.Repo.BenefitList.get_by_rx_date_and_plan_id(plan_id, rx_date)
    |> verify_benefit_list_list
  end

  defp verify_benefit_list_list([])do
    {:error, "49"}
  end

  defp verify_benefit_list_list(benefit_list_list)do
    benefit_list_list
  end

  def validate_list([h | t], days_supply, drug, compound_code) do
    case valid?(h, days_supply, drug, compound_code) do
      true -> h 
      false -> validate_list(t, days_supply, drug, compound_code)
    end
  end

  def validate_list([], _days_supply, _drug, _compound_code) do
    nil 
  end
  
  def valid?(%{benefit_item_type: "F"}, _days_supply, _drug, compound_code) do
    compound_code == "2"
  end

  def valid?(%{benefit_item_type: "N"} = bli, _days_supply, {drug_item, _prices} , _compound_code) do
    drug_item.ndc_upc_hri == bli.ndc 
  end

  def valid?(%{benefit_item_type: "V"} = bli, days_supply, _drug, _compound_code) do
     is_valid_ds?(days_supply, bli.value_ds)
  end

  def valid?(%{benefit_item_type: "A"} , _days_supply, _drug, _compound_code) do
    true
  end

  def valid?(%{}, _days_supply, _drug, _compound_code) do
     false
  end
  
  def is_valid_ds?(days_supply, value)do
    {lower, upper} = decode_value(value)
    
    days_supply >= lower && days_supply <= upper
  end

  defp decode_value(value) do
    bounds = String.replace(value, "-","-0")
      |> String.replace("+","")
      |> String.split("-")
      |> Enum.map( fn x -> String.to_integer(x) end)
     
      lower = Enum.at(bounds,0)
      upper = Enum.at(bounds,1)
      
      if upper == 0 do 
        {upper, lower}
      else
        {lower, upper}
      end
  end

end
