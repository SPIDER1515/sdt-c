defmodule NA.ADJ.Modifiers.Copay do

  alias NA.Claims.ClaimAgent
  alias NA.Claims.ClaimField
  alias NA.DB.Repo.Claims

  @moduledoc """
  Provides a set of functions to match and calculate the copay.

  `get_copay/6` is the main function that calls all the necessary functions to
  determine the copay amount.

  A copay is first matched using `validate_matched_copay/5`
  Once a match is found, the copay is sent to `calculate_copay/3` to match on the calculation_type
  to determine which logic will be used to calculate the copay.
  
  There are 15 calculation types available for copay:
    * ('01', MIN $$$ ONLY');
    * ('02','PERCENT ONLY');
    * ('03','MIN $$$ PLUS PERCENT'); 
    * ('04','LESSER OF MAX $$$ AND PERCENT');
    * ('05','GREATER OF MIN $$$ AND PERCENT');
    * ('06','MIN $$$ PLUS NET PERCENTAGE');
    * ('07','PERCENT BETWEEN MIN AND MAX');
    * ('08','(TP > MAX) ? PERCENT : MIN $$$');
    * ('09','MIN $$$ + (PCT * MAX(TP-MAX, 0))'); 
    * ('10','MIN + (PCT * MAX(TP-MAX-MIN, 0))');
    * ('11','(TP > $PCT) ? $MAX : $MIN'); 
    * ('12','USE SUBMITTED COPAY');
    * ('13','PERCENT * MIN(DS, MAX)/DS');
    * ('14','MIN $ PLUS PERCENT UP TO MAX $');
    * ('16','(TP > MAX) ? MIN $$$ : PERCENT');

  All the arithmetic is performed using Decimal wrapper functions and
  the result is then rounded and returned as a float.
  """

  @doc """
  Main function that calls all the other functions in the module to
  return the matched copay with the calculated amount.
  """
  def get_copay(pid, claim_id, copay_id, auxiliary, mony_type, copay_basis) do
    with [_|_] = items <- get_copay_list(copay_id),
         %{} = cc <- get_claim(claim_id),
         %{} = copay <- find_copay_item(items, pid, cc, auxiliary, mony_type, copay_basis),
         drug_cost <- get_drug_cost(cc),
         {:ok, copay_amount} <- calculate_copay(copay, drug_cost, pid)
    do
      {copay, copay_amount}
    else
      error -> error
    end
  end

  defp get_copay_list(id) do
    case NA.DB.Repo.Modifiers.get_copay_by_id(id) do
      {_, list} -> list
      _ -> {:error, "No copay list found"}
    end
  end

  defp get_claim(claim_id) do
    case Claims.get_by_id(claim_id) do
      %{} = claim -> claim
      _ -> {:error, "No claim found"}
    end
  end

  defp find_copay_item(items, pid, cc, auxiliary, mony_type, copay_basis) do
    with {:ok, ds} <- get_ds(pid),
         {:ok, qty} <- get_qty(pid),
         matched_items <- match_copay_list(items, auxiliary, mony_type, copay_basis)
    do
      ingr_disp_tax = get_drug_cost(cc)
      validate_matched_copay(matched_items, ds, qty, ingr_disp_tax, cc.ingredient_cost)
    else
      error -> error
    end
  end
  
  @doc """
  Returns a filtered list of copays matching
  on auxiliary, mony_type and copay_basis.
  """
  def match_copay_list(copay_list, auxiliary, mony_type, copay_basis) do
    Enum.filter(copay_list, fn(i) -> is_match_mony?(i.mony_type, mony_type) && 
                              i.auxiliary == auxiliary &&
                              i.copay_basis == copay_basis
                              end)
  end

  @doc """
  Matches on the copay_basis and compares it 
  against the tier_max to return the copay line
  that will be used for the calculation.
  """
  def validate_matched_copay(copay_list, ds, qty, ingr_disp_tax, cost) do
    copay = match_copay(copay_list, ds, qty, ingr_disp_tax, cost)

    case copay do
      %{} -> copay
      _-> {:error, "No copay match"}
    end
  end

  defp match_copay([%{copay_basis: "D"} = _|_] = items, ds, _qty, _ingr_disp_tax, _cost) do
    Enum.find(items, fn(i) -> ds <= i.tier_max end)
  end

  defp match_copay([%{copay_basis: "Q"} = _|_] = items, _ds, qty, _ingr_disp_tax, _cost) do
    Enum.find(items, fn(i) -> qty <= i.tier_max end)
  end

  defp match_copay([%{copay_basis: "I"} = _|_] = items, _ds, _qty, ingr_disp_tax, _cost) do
    Enum.find(items, fn(i) -> ingr_disp_tax <= i.tier_max end)
  end

  defp match_copay([%{copay_basis: "C"} = _|_] = items, _ds, _qty, _ingr_disp_tax, cost) do
    Enum.find(items, fn(i) -> cost <= i.tier_max end)
  end

  @doc """
  Matches on the copay calculation_type to determine which logic
  to use for determining the copay amount.
  
  ## ('01', 'MIN $$$ ONLY')
  If the copay fee_numeric is less than or equal to the drug_cost return the drug_cost 
  otherwise return the fee_numeric.

  ### Examples
  
      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 01, fee_numeric: 15}, 11.43)
      11.43

      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 01, fee_numeric: 15}, 15.43)
      15

  ## ('02', 'PERCENT ONLY')
  The copay is calculated by multiplying the percent entered in the percent field
  by the cost of the drug.

  ### Examples

      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 02, percent: 50}, 278.13)
      139.07
   
  ## ('03', 'MIN $$$ PLUS PERCENT')
  The copay is the sum of the amount in the fee_numeric field plus the 
  percent amount calculated by multiplying the percent field by the
  cost of the drug.

  ### Examples
  
      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 03, fee_numeric: -50, percent: 100},
      ...> 6.25)
      0.00

  ## ('04', 'LESSER OF MAX $$$ AND PERCENT')
  The copay is the lesser of the amount in the max_fee field or the amount calculated
  by multiplying the percent field by the cost of the drug.

  ### Examples
  
      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 04, max_fee: 145, percent: 30},
      ...> 247.16)
      74.15     

      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 04, max_fee: 145, percent: 30},
      ...> 1000.00)
      145

  ## ('05', 'GREATER OF MIN $$$ AND PERCENT')
  The copay is the greater of the amount in the fee_numeric field or
  the amount calculated by multiplying the percent field by
  the cost of the drug.

  ### Examples
  
      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 05, fee_numeric: 45, percent: 20},
      ...> 291.94)
      58.39

      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 05, fee_numeric: 45, percent: 20},
      ...> 150.15)
      45

  ## ('06', 'MIN $$$ PLUS NET PERCENTAGE')
  The net percentage is determined first subtracting the fee_numeric field from
  the cost of the drug. The net cost is then multiplied by the percentage entered
  into the percent field which is then added with the fee_numeric field.

  ### Examples
  
      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 06, fee_numeric: 35, percent: 10},
      ...> 310.55)
      62.56     

      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 06, fee_numeric: 35, percent: 20},
      ...> 310.55)
      90.11


  ## ('07', 'PERCENT BETWEEN MIN AND MAX')
  The copay is determined by comparing:

  a) The amount calculated by multiplying the percentage in the percent field by the cost of the drug.

  b) The amount entered in the fee_numeric field

  c) The amount entered in the max_fee field

  If the amount in a) is between the amount in b) and c), then a is the copay.

  If the amount calculated in a) is less than b), then b is the copay.

  If the amount in a) is more than c), then c) is the copay.

  ### Examples
  
      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 07, fee_numeric: 20, max_fee: 100, percent: 10},
      ...> 940.20)
      94.02

      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 07, fee_numeric: 10, max_fee: 50, percent: 10},
      ...> 8.34)
      8.34

      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 07, fee_numeric: 10, max_fee: 50, percent: 10},
      ...> 11.34)
      10.00

      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 07, fee_numeric: 10, max_fee: 50, percent: 10},
      ...> 525.41)
      50.00

  ## ('08', 'TP > MAX ? PERCENT : MIN $$$')
  The copay is determined by taking the cost of the drug and comparing that value in the max_fee field.

  If the cost of the drug is less than the amount in that field, then the fee_numeric is the copay.

  If the cost of the drug is more than the max_fee field, the copay is calculated by
  multiplying the percent value by the cost of the drug.

  ### Examples
  
      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 08, fee_numeric: 12.50, max_fee: 750, percent: 25},
      ...> 106.22)
      12.50

      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 08, fee_numeric: 12.50, max_fee: 750, percent: 25},
      ...> 849.73)
      212.43

  ## ('09', 'MIN $$$ + (PCT * MAX(TP-MAX, 0))')
  The copay is determined by taking the cost of the drug and comparing that value in the max_fee field.

  If the cost of the drug is less than the amount, then the fee_numeric amount is the copay.

  If the cost of the drug is more than the max_fee field the copay is calculated by multiplying the
  percent amount in the percent field by the amount of the drug cost over the max_fee value then
  adding the fee_numeric amount to it.

  ### Examples
  
      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 09, fee_numeric: 100, max_fee: 750, percent: 100},
      ...> 212.43)
      100

      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 09, fee_numeric: 100, max_fee: 750, percent: 100},
      ...> 3930.00)
      3280.0

  ## ('10', 'MIN $$$ + (PCT * MAX(TP-MAX-MIN, 0))')
  The cost of the drug is compared to the max_fee + fee_numeric.

  If the cost of the drug is less than that amount, then the fee_numeric is the copay.

  Otherwise the copay is calculated by taking the amount in the percent field
  and multiplying that by the amount of the drug cost over max_fee plus
  fee_numeric and then adding fee_numeric to that amount.

  ### Examples
  
      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 10, fee_numeric: 15, max_fee: 100, percent: 100},
      ...> 106.22)
      15

      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 10, fee_numeric: 15, max_fee: 100, percent: 50},
      ...> 212.43)
      63.72

  ## ('11', '(TP > $PCT)? $MAX: $MIN')
  The copay is determined by taking the cost of the drug and
  comparing that value to the percent field, only in this case
  the percent value is treated as a dollar amount.

  If the cost of the drug is more than the "dollar" amount shown in the
  percent field, then the max_fee is the copay amount.

  Otherwise the fee_numeric is the copay amount.

  ### Examples
  
      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 11, fee_numeric: 15, max_fee: 25, percent: 100},
      ...> 435.45)
      25

      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 11, fee_numeric: 15, max_fee: 25, percent: 100},
      ...> 73.83)
      15

  ## ('12', 'USE SUBMITTED COPAY')
  The amount submitted in the Other Payer Patient Responsibility Amount(352-NQ)
  is used as the submitted copay.

  ## ('13', 'PERCENT * MIN(DS, MAX)/DS')
  This is the percent copay base on the days supply value in the max_fee
  field. When the days supply is less than or equal to the value in the max_fee
  take the percent multiplied by the drug cost.

  ## ('14', 'MIN $ PLUS PERCENT UP TO MAX $')
  If the total cost of the drug is below fee_numeric, then the total cost is copay.

  Otherwise the copay is the sum of the amount in the fee_numeric field plus
  the percent amount calculated by multiplying the percent entered in the percent
  field by the cost of the drug, up to max_fee amount.

  ### Examples
  
      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 14, fee_numeric: 50, max_fee: 300, percent: 5},
      ...> 589.96)
      79.50

      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 14, fee_numeric: 50, max_fee: 300, percent: 5},
      ...> 17.38)
      17.38

  ## ('16', '(TP > MAX) ? MIN $$$ : PERCENT')
  The copay is determined by taking the cost of the drug and comparing that value in the
  max_fee field.

  If the cost of the drug is less than that amount then the copay is the cost of the 
  drug times the amount in the percent.

  Otherwise the copay is the cost of the drug times the amount in the percent. If the cost of
  the drug is more than the amount in the max_fee field, then the fee_numeric amount is the copay.

  ### Examples
  
      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 16, fee_numeric: 10, max_fee: 300, percent: 30},
      ...> 988.24)
      10

      iex> NA.ADJ.Modifiers.Copay.calculate_copay(%{calculation_type: 16, fee_numeric: 10, max_fee: 300, percent: 30},
      ...> 3.1)
      0.93

  """
  def calculate_copay(copay, drug_cost, pid \\ nil)

  def calculate_copay(%{calculation_type: 01} = copay, drug_cost, _pid) do
    case copay.fee_numeric >= drug_cost do
      true -> drug_cost
      false -> copay.fee_numeric
    end
  end
  
  def calculate_copay(%{calculation_type: 02} = copay, drug_cost, _pid) do
    get_drug_percent(drug_cost, copay.percent)
    |> round_decimal
  end

  def calculate_copay(%{calculation_type: 03} = copay, drug_cost, _pid) do
    drug_cost_percent = get_drug_percent(drug_cost, copay.percent)
    copay = add(copay.fee_numeric, drug_cost_percent)
    |> round_decimal 

    case copay >= 0 do
      true -> copay
      false -> 0.00
    end
  end

  def calculate_copay(%{calculation_type: 04} = copay, drug_cost, _pid) do
    drug_cost_percent = get_drug_percent(drug_cost, copay.percent)
    |> round_decimal 

    case copay.max_fee >= drug_cost_percent do
      true -> drug_cost_percent
      false -> copay.max_fee
    end
  end

  def calculate_copay(%{calculation_type: 05} = copay, drug_cost, _pid) do
    drug_cost_percent = get_drug_percent(drug_cost, copay.percent)
    |> round_decimal
    
    case copay.fee_numeric >= drug_cost_percent do
      true -> copay.fee_numeric 
      false -> drug_cost_percent
    end
  end

  def calculate_copay(%{calculation_type: 06} = copay, drug_cost, _pid) do
    percentage = divide(copay.percent, 100)
    subtract(drug_cost, copay.fee_numeric)
    |> multiply(percentage)
    |> add(copay.fee_numeric)
    |> round_decimal
  end

  def calculate_copay(%{calculation_type: 07} = copay, drug_cost, _pid) do
    get_drug_percent(drug_cost, copay.percent)
    |> determine_copay(drug_cost, copay.fee_numeric, copay.max_fee)
    |> round_decimal
  end

  def calculate_copay(%{calculation_type: 08} = copay, drug_cost, _pid) do
    case drug_cost <= copay.max_fee do
      true -> copay.fee_numeric
      false -> 
        get_drug_percent(drug_cost, copay.percent)
        |> round_decimal 
    end
  end

  def calculate_copay(%{calculation_type: 09} = copay, drug_cost, _pid) do
    case drug_cost <= copay.max_fee do
      true -> copay.fee_numeric
      false -> 
        subtract(drug_cost, copay.max_fee)
        |> get_drug_percent(copay.percent)
        |> add(copay.fee_numeric)
        |> round_decimal
    end
  end

  def calculate_copay(%{calculation_type: 10} = copay, drug_cost, _pid) do
    max_min = add(copay.fee_numeric, copay.max_fee)

    case drug_cost <= max_min do
      true -> copay.fee_numeric
      false ->
        subtract(drug_cost, max_min)
        |> get_drug_percent(copay.percent)
        |> add(copay.fee_numeric)
        |> round_decimal
    end
  end

  def calculate_copay(%{calculation_type: 11} = copay, drug_cost, _pid) do
    case drug_cost <= copay.percent do
      true -> copay.fee_numeric
      false -> copay.max_fee
    end
  end

  def calculate_copay(%{calculation_type: 12}, _drug_cost, pid) do
    get_ppr(pid) 
  end

  def calculate_copay(%{calculation_type: 13} = copay, drug_cost, pid) do
    ds = get_ds(pid)

    case ds <= copay.max_fee do
      true -> 
        get_drug_percent(drug_cost, copay.percent)
        |> round_decimal
      false ->
        get_drug_percent(drug_cost, copay.percent)
        |> divide(ds)
        |> multiply(copay.max_fee)
        |> round_decimal
    end
  end

  def calculate_copay(%{calculation_type: 14} = copay, drug_cost, _pid) do
    case drug_cost <= copay.fee_numeric do
      true -> drug_cost
      false -> 
        get_drug_percent(drug_cost, copay.percent)
        |> add(copay.fee_numeric)
        |> round_decimal
    end
  end

  def calculate_copay(%{calculation_type: 16} = copay, drug_cost, _pid) do
    case drug_cost <= copay.max_fee do
      true -> 
        get_drug_percent(drug_cost, copay.percent)
        |> round_decimal
      false -> copay.fee_numeric
    end
  end

  def calculate_copay(_copay, _drug_cost, _pid) do
    {:error, "Invalid calculation type for copay"}
  end

  defp determine_copay(cost, _drug_cost, fee_numeric, max_fee) when cost >= fee_numeric and cost <= max_fee, do: cost

  defp determine_copay(cost, drug_cost, fee_numeric, _max_fee) when cost <= fee_numeric do 
    case drug_cost <= fee_numeric do
      true -> drug_cost
      false -> fee_numeric
    end
  end

  defp determine_copay(cost, _drug_cost, _fee_numeric, max_fee) when cost >= max_fee, do: max_fee

  defp get_drug_cost(claim) do
    add(claim.group_ingredient_cost, claim.group_disp_fee)
    |> add(claim.group_sales_tax)
    |> round_decimal
  end

  defp get_drug_percent(drug_cost, percent) do
    divide(percent, 100)
    |>
    multiply(drug_cost)
  end

  defp round_decimal(number) do
    Decimal.round(Decimal.new(number), 2)
    |> Decimal.to_float
  end

  defp add(num1, num2) do
    Decimal.add(Decimal.new(num1), Decimal.new(num2))
    |> Decimal.to_float
  end

  defp subtract(num1, num2) do
    Decimal.sub(Decimal.new(num1), Decimal.new(num2))
    |> Decimal.to_float
  end

  defp multiply(num1, num2) do
    Decimal.mult(Decimal.new(num1), Decimal.new(num2))
    |> Decimal.to_float
  end

  defp divide(num1, num2) do
    Decimal.div(Decimal.new(num1), Decimal.new(num2))
    |> Decimal.to_float
  end

  defp get_ds(pid) do
    case ClaimAgent.find_claim_field(pid, "405", 1) do
      nil -> {:reject, "19"}
      %ClaimField{value: value} -> value
    end
  end

  defp get_qty(pid) do
    case ClaimAgent.find_claim_field(pid, "442", 1) do
      nil -> {:reject, "E7"}
      %ClaimField{value: value} -> value
    end
  end

  defp get_ppr(pid) do
    case ClaimAgent.find_claim_field(pid, "352", 1) do
      nil -> {:reject, "329"}
       %ClaimField{value: value} -> value
    end
  end


  defp is_match_mony?(mony_type, "N"), do: mony_type == "M"
  defp is_match_mony?(mony_type, multi_source_code), do: mony_type == multi_source_code

end
