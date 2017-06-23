defmodule NA.Adj.Pricer do

  alias NA.ADJ.Drug
  alias NA.DB.Schema.CostList, as: CTL
  alias NA.DB.Schema.PlanMacList, as: PMacList
  alias NA.ADJ.Plan.BenefitList
  alias NA.ADJ.Modifier.DispFee
  alias NA.ADJ.Modifier.Cost
  alias NA.ADJ.Pharmacy

  def try_get_price({_a, _info}= res)do
    res
  end
  
  def try_get_price(ndc, service_provider, submitted_group ,member_id, person_code,
   rx_date, days_supply, quantity, ic, uc, compound_code) do
    claim_info = 
      %{rx_date: rx_date, product_id: ndc, service_provider: service_provider, 
       days_supply: days_supply, quantity: quantity, ic: ic, uc: uc, 
       compound_code: compound_code, pp:  nil, modifiers: nil, member_id: member_id,
       person_code: person_code, submitted_group: submitted_group}
    
    try do 
      get_price(claim_info)
    catch
      :exit, err ->
        IO.inspect err
        try_get_price(ndc, service_provider, submitted_group, member_id, person_code,
         rx_date, days_supply, quantity, ic, uc, compound_code)
    end
  end

  defp get_price(claim_info) do
    claim_info
    |> apply_timed_function(:find_pricing_items)
    |> apply_timed_function(:find_drug_info)
    |> apply_timed_function(:find_pharmacy)
    |> apply_timed_function(:find_group_plan)
    |> apply_timed_function(:find_plan)
    |> apply_timed_function(:find_pharmacy_panel)
    |> apply_timed_function(:find_mac_price)
    |> apply_timed_function(:find_calculator)
    |> apply_timed_function(:find_disp_fee_info)
    |> apply_timed_function(:find_cost_list)
    |> apply_timed_function(:find_pricing_criteria)
    |> apply_timed_function(:find_pharmacy_tax)
    |> apply_timed_function(:calculate_results)
  end
  
  def find_drug_info({:error, _rej} = rej), do: rej
  def find_drug_info(plan_info) do
    with %{} = drug_info <- Drug.get_drug(plan_info.product_id, plan_info.rx_date) do
      Map.merge(plan_info, drug_info)
    else 
      rslt -> rslt
    end
  end

  def find_pharmacy({:error, _rej} = rej), do: rej
  def find_pharmacy(plan_info) do
    with %{} = pharmacy <- Pharmacy.get_by_nabp(plan_info.service_provider, plan_info.rx_date) do
      Map.put(plan_info, :pharmacy, pharmacy)
    else 
      rslt -> rslt
    end
  end
  
  def find_pharmacy_tax({:error,  _rej} = rej)do
    rej
  end

  def find_pharmacy_tax(plan_info)do
    pharmacy_state_code = String.slice(plan_info.pharmacy.nabp, 0..1)

    pharmacy_tax = 
      case get_pharmacy_tax(pharmacy_state_code, plan_info.pharmacy.address.zip_code, plan_info.rx_date) do
        [] -> get_pharmacy_tax(pharmacy_state_code, nil, plan_info.rx_date)
        pt -> pt
      end
    final_tax = process_tax(pharmacy_tax, plan_info)
  
    case pharmacy_tax do
      {:error, _rej} = rej -> rej
      [t|_] -> Map.put(plan_info, :pharmacy_tax, t)
               |> Map.put(:final_tax, final_tax)
     end
  end

  defp get_pharmacy_tax(pharmacy_state_code, zip, rx_date)do
    zip = case zip do
      nil -> nil
      s -> String.slice(s,0..5)
    end

    NA.DB.Repo.PharmacyTax.get_by_ncpdp_state_code_and_zip(pharmacy_state_code, zip, rx_date)
  end

  defp process_tax([pharmacy_tax], plan_info)do
    {drug, _} = plan_info.drug
 
    with true <- String.starts_with?(drug.gpi, "970510") do
       pharmacy_tax.alternate_tax
    else
      _ -> case drug.rx_otc_indicator_code in ["O", "P"] do
            true -> pharmacy_tax.standard_tax
            false -> pharmacy_tax.prescription_tax
           end
    end
  end

  def find_pricing_items(plan_info)do
    case get_pricing_items(plan_info) do
      {{:error, rej}} -> {:error, rej}
      {group} -> Map.put(plan_info, :group, group)
    end
  end

  def get_compound_price(service_provider,submitted_group, member_id, person_code,
  rx_date, days_supply, ingredients_info)do
    process_ingredients(service_provider, submitted_group, member_id, person_code, 
    rx_date, days_supply, ingredients_info, [], nil)
  end

  ########################## START MAC REGION ###########################
  def find_mac_price({:error, _err} = err)do 
    err
  end

  def find_mac_price(plan_info)do
    {drug, _prices} = plan_info.drug
    pp_mac = match_pp_mac_items(plan_info.pp.mac_items, plan_info.rx_date)

    mac_list = find_valid_mac_list(plan_info.mac_lists, plan_info.drug)

    valid_mac_id = case pp_mac do 
    nil ->  mac_list.mac_1_id
    pp_mac -> pp_mac.mac_id
    end
    
    mac_price = case get_by_mac_id_and_value_and_rx_date(valid_mac_id, drug.gpi, plan_info.rx_date)do
      [_|_] = m -> m
      {:error, _} -> nil
      _ -> get_by_mac_id_and_value_and_rx_date(mac_list.mac_1_id, drug.ndc_upc_hri, plan_info.rx_date)
      end
      |> find_valid_mac(plan_info.rx_date)
    
      Map.put(plan_info,:mac_price, mac_price)  
  end

  defp match_pp_mac_items([h|t], rx_date)do
    case date_is_active(rx_date, h.start_date, h.end_date)do
      true -> h
      false -> match_pp_mac_items( t, rx_date)
    end
  end

  defp match_pp_mac_items([], _rx_date)do
    nil
  end

  defp match_pp_mac_items(nil, _rx_date)do
    nil
  end

  defp find_valid_mac([h|t], rx_date)do
    case date_is_active(rx_date, h.start_date, h.end_date)do
      true -> h
      false -> find_valid_mac(t, rx_date)
    end
  end

  defp find_valid_mac(nil, _rx_date)do
    nil
  end
  
  defp find_valid_mac([], _rx_date)do
    IO.puts "no valid mac"
    nil
  end

  defp find_valid_mac_list([h|t], drug )do
    case match_mac_list(h)do
      %PMacList{} = p -> p
      _ -> find_valid_mac_list(t, drug)
    end
  end
  
  defp match_mac_list(%PMacList{claim_type: ct} = pml) when ct == "R" do
   pml
  end

  defp match_mac_list(_pml) do
    false
  end

  defp get_by_mac_id_and_value_and_rx_date(id, value, rx_date)do
    NA.DB.Repo.Mac.get_by_mac_id_and_value_and_rx_date(id, value, rx_date)
    |> verify_mac_price
  end
  
  defp verify_mac_price(nil)do
    #IO.puts "No Mac price"
    nil
  end

  defp verify_mac_price(st)do
    st
  end
  
  ################### END OF THE MAC REGION ####################################
  def find_cost_list({:error, _err} = err)do
    err
  end

  def find_cost_list(plan_info)do
    { _,cost_list} = case plan_info.modifiers.cost_modifier do
        nil -> Cost.get_cost(plan_info.ppc.cost_modifier)
        cm -> Cost.get_cost(cm)
     end
     cost_lists = match_cost(plan_info.drug, cost_list)

     Map.put(plan_info, :cost_lists, cost_lists)
  end

  def find_pricing_criteria({:error, _err} = err) do
    err
  end

  def find_pricing_criteria(plan_info)do
    pricing_criteria = Cost.get_cost_method_type(plan_info.cost_lists)
    Map.put(plan_info , :pricing_criteria, pricing_criteria)
  end

  def calculate_results({:error, _err} = err)do
    err
  end

  def calculate_results(plan_info)do
    results = get_results(plan_info)

    case results do
      {:error, _err} = err -> err
      s -> Map.put(plan_info, :results, s)
    end
  end

  defp get_results(plan_info)do
    prices = 
      create_prices(plan_info.drug, plan_info.effective_price, plan_info.quantity,
      plan_info.disp_fee_list, plan_info.cost_lists, plan_info.ic, plan_info.uc, 
      plan_info.mac_price, [], plan_info.compound_code)
      |> Enum.group_by(fn {_,_,usage_criteria,_} -> usage_criteria end)

     priced = case plan_info.pricing_criteria do
       "lt" -> get_lowest(prices[:used_in_calc])
       "gt" -> get_highest(prices[:used_in_calc])
     end
     {final_price, _, _, disp_fee} = priced 
     calculated_tax = 
      with false <- 
        is_nil(plan_info.pharmacy_tax.flat_tax) do
           Decimal.add(final_price, disp_fee)
           |> Decimal.mult(plan_info.final_tax)
           |> Decimal.add(plan_info.pharmacy_tax.flat_tax)
      else _  -> 
         Decimal.add(final_price, disp_fee)
         |> Decimal.mult(plan_info.final_tax)
      end

     Map.put(plan_info,:final_price, priced)
     |> Map.put(:inf_1, prices[:not_used_in_calc])
     |> Map.put(:final_eff, plan_info.effective_price.unit_price)
     |> Map.put(:info_2, " ")
     |> Map.put(:mac_price, plan_info.mac_price)
     |> Map.put(:info_3, " ")
     |> Map.put(:calculated_tax, calculated_tax) 
  end

 
  defp create_prices({d, _} = drug, effective_price,quantity, disp_fee_list, 
  [%CTL{cost_basis: cb} = h | t] , ic, uc, mac_price, prices, compound_code) 
  when cb == "AWP" do
     awp = Decimal.new(quantity)
        |> Decimal.mult(effective_price.extended_unit_price)
        |> Decimal.mult( h.percentage)
        |> Decimal.div(Decimal.new(100))
        |> is_used_in_calc?(cb,h.mony_type, d.multi_source_code)
        
     used_disp_fee = DispFee.get_disp_fee_to_apply(disp_fee_list, h.disp_fee)
     awp = Tuple.append(awp, used_disp_fee)
     create_prices(drug, effective_price, quantity, disp_fee_list, t, ic, uc, mac_price, [awp|prices], compound_code)
  end

  defp create_prices({d, _} = drug, effective_price, quantity,disp_fee_list, 
   [%CTL{cost_basis: cb}= h | t], ic, uc, mac_price, prices, compound_code) 
  when cb == "UMAC" do
    mac_price = case mac_price do
      nil -> %{price: 8000}
      m -> m
    end

    umac = Decimal.new(quantity)
           |> Decimal.mult(Decimal.new(mac_price.price))
           |> Decimal.mult(h.percentage)
           |> Decimal.div(Decimal.new(100))
           |> is_used_in_calc?(cb, h.mony_type, d.multi_source_code)

    used_disp_fee = DispFee.get_disp_fee_to_apply(disp_fee_list, h.disp_fee)
    umac = Tuple.append(umac, used_disp_fee)

    create_prices(drug,effective_price,quantity, disp_fee_list, t, ic, uc, mac_price, [umac|prices], compound_code)
  end

  defp create_prices({d, _} = drug,
   effective_price,
   quantity,
   disp_fee_list,
   [%CTL{cost_basis: cb } = h | t],
   ic,
   uc,
   mac_price,
   prices, 
   compound_code) when cb == "I/C"do
      
    new_ic = Decimal.new(ic)
            |> Decimal.mult(h.percentage)
            |> Decimal.div(Decimal.new(100))
            |> is_used_in_calc?(cb,h.mony_type, d.multi_source_code)

    used_disp_fee = DispFee.get_disp_fee_to_apply(disp_fee_list, h.disp_fee)
    new_ic = Tuple.append(new_ic, used_disp_fee)
    create_prices(drug, effective_price, quantity, disp_fee_list, t, ic, uc, mac_price,[ new_ic| prices], compound_code)
  end 

  defp create_prices({d, _} = drug,
   effective_price,
   quantity,
   disp_fee_list,
   [%CTL{cost_basis: cb} = h | t ],
   ic,
   uc,
   mac_price,
   prices,
   compound_code) when cb == "GEN" do
      quantity = Decimal.new(quantity)
      hundred = Decimal.new(100);
      o_price = Decimal.mult(effective_price.extended_unit_price, h.percentage)
        |> Decimal.mult(quantity)
        |> Decimal.div(hundred)
        |> is_used_in_calc?(cb,h.mony_type, d.multi_source_code)

      {_, cost_lists} = Cost.get_cost(h.parent_id)

      cost_lists = Enum.filter(cost_lists,fn c -> c.mony_type == "G" end)

      used_disp_fee = DispFee.get_disp_fee_to_apply(disp_fee_list, h.disp_fee)
      o_price = Tuple.append(o_price, used_disp_fee)

      case h.percentage == hundred && d.multi_source_code == "O"do
        false -> create_prices(drug, effective_price, quantity, disp_fee_list, t, ic, uc,mac_price, [o_price | prices], compound_code)
        true  -> create_prices(drug, effective_price, quantity, disp_fee_list, cost_lists++t, ic, uc,mac_price, [o_price | prices], compound_code)
      end
   end

  defp create_prices(drug, effective_price, quantity, disp_fee_list, [_|t], ic, uc,mac_price, prices, compound_code) do
    create_prices(drug, effective_price, quantity, disp_fee_list, t, ic, uc,mac_price, prices, compound_code)
  end

  defp create_prices(_drug, _effective_price, _quantity, _disp_fee_list, [], _ic, _uc,_mac_price, prices, _compound_code), do: prices

  defp get_pricing_items(plan_info) do
    group = get_group(plan_info.submitted_group)

    {group}
  end

  defp is_used_in_calc?(price,cost_basis,mony_code,multi_source_code) do
      case is_match_mony_type?(mony_code, multi_source_code) do
       true -> {price, cost_basis,:used_in_calc}
       false -> {price, cost_basis, :not_used_in_calc}
      end
  end

  ################### START OF PLAN REGION #################
  defp get_plan(id) do
    NA.DB.Repo.Plan.get_by_id(id)
    |> verify_plan
  end

  defp verify_plan(nil) do
    {:error, "91"}
  end

  defp verify_plan(plan) do
    plan
  end

  defp match_valid_plan_benefit_list_list([], _plan_info)do
    {:error, "79"}
  end

  defp match_valid_plan_benefit_list_list([h|t], plan_info)do
    new_plan_info = validate_bli(h, plan_info)
      |> validate_pbll_pharmacy_panel

    case new_plan_info do
      nil -> match_valid_plan_benefit_list_list(t, plan_info)
      %{pp:  nil} -> match_valid_plan_benefit_list_list(t, new_plan_info)
      %{modifiers: nil} -> match_valid_plan_benefit_list_list(t, new_plan_info)
      reslt-> reslt
    end
  end

  defp validate_bli(pbll_bli_h, %{modifiers: nil} = plan_info)  do
    case BenefitList.valid?(pbll_bli_h, plan_info.days_supply,plan_info.drug, plan_info.compound_code) do
      true -> {pbll_bli_h, %{plan_info| modifiers: pbll_bli_h}}
      false -> nil
    end
  end

  defp validate_bli(pbll, plan_info)do
    {pbll, plan_info}
  end

  defp validate_pbll_pharmacy_panel(nil)do
    nil
  end

  defp validate_pbll_pharmacy_panel({%{pharmacy_panel_id: nil}, plan_info})do
    plan_info
  end

  defp validate_pbll_pharmacy_panel({pbll, %{pharmacy: pharmacy} = plan_info})do
    pp =  
      with false <- is_nil(pharmacy.affiliation_list) do
            NA.Adj.PharmacyPanel.get_pharmacy_panel_item(pbll.pharmacy_panel_id,
            pharmacy.nabp, 
            pharmacy.affiliation_list.affiliation_code,
            plan_info.rx_date)
      else
        _-> NA.Adj.PharmacyPanel.get_pharmacy_panel_item(pbll.pharmacy_panel_id,
            pharmacy.nabp, 
            nil,
            plan_info.rx_date)
      end
          
    %{plan_info| pp: pp}
  end
  
  def find_plan({:error, _rej} = rej)do
    rej
  end

  def find_plan(plan_info) do
    case get_plan(plan_info.group_plan.plan_id)do
      {:error, _rej} = rej -> rej
      s -> Map.put(plan_info, :plan, s)
    end
  end

  #################### END OF PLAN REGION #################

  ########## START CALCULATOR REGION ##########
  defp apply_timed_function({:error, _rej} = rej, _function_name)do
    rej
  end

  defp apply_timed_function(plan_info, function_name)do
    {time, new_plan_info} = :timer.tc(
     fn -> apply(NA.Adj.Pricer, function_name, [plan_info])end)
    
    case new_plan_info do
      {:error, _rej} = rej -> rej
       new -> Map.put(new, function_name, time)
    end
  end

  def find_calculator({:error, _err} = err) do
    err
  end

  def find_calculator(inf)do
    match_calculator(inf.rx_date, inf.days_supply, inf.pp.calculators, inf.compound_code) 
    |> case do
      {:error, _err} = err -> err
      ppc -> Map.put(inf, :ppc, ppc)
      end
  end

  defp match_calculator(rx_date,
   days_supply,
   [%{calculator_type: "F"} = ppc | t],
   compound_code)when compound_code == "2" do
     days_supply = case days_supply < 0 do
        true -> days_supply * -1
        false -> days_supply
      end
      case date_is_active(rx_date, ppc.start_date, ppc.end_date)do
        true -> ppc
        false -> match_calculator( rx_date,days_supply, t, compound_code)
    end


   end
  defp match_calculator(rx_date,
    days_supply,
    [%{calculator_type: "V"} = ppc | t], compound_code) do

    case date_is_active(rx_date, ppc.start_date, ppc.end_date)
        && BenefitList.is_valid_ds?(days_supply, ppc.value_ds) do
        true -> ppc
        false -> match_calculator(rx_date, days_supply, t, compound_code)
    end
  end

  defp match_calculator(_rx_date, _days_suppy, nil, _compound_code)do
    {:error, "74"}
  end
  
  defp match_calculator(_rx_date,_days_supply, [], _compound_code)do
    {:error, "98"}
  end 

  defp match_calculator(rx_date,days_supply, [_ | t], compound_code)do
    match_calculator(rx_date,days_supply, t, compound_code)
  end

  ########## END CALCULATOR REGION ##########

  def find_pharmacy_panel({:error, _err} = rej) do
   rej
  end
  
  def find_pharmacy_panel(plan_info)do
    {p_plan, _pblls, mac_lists} = plan_info.plan
    new_plan_info = Map.put(plan_info, :mac_lists, mac_lists)
    BenefitList.get_benefit_list_list(p_plan.id, plan_info.rx_date)
    |>
    match_valid_plan_benefit_list_list(new_plan_info)
  end
  

########## START DISP FEE REGION ##########

  def find_disp_fee_info({:error, _err}= err)do
    err
  end

  def find_disp_fee_info(plan_info) do
    disp_fee_lists = DispFee.get_disp_fee(plan_info)
    match_disp_fee(plan_info.drug, disp_fee_lists)
    |> case do
      {:error, _err} = err -> err
      rslt-> Map.put(plan_info, :disp_fee_list, rslt)
    end
  end

  defp match_disp_fee(_drug, []) do
    {:error, "59"}
  end

  defp match_disp_fee(drug, [h | t]  ) do
    {d, _} = drug
    case is_match_mony_type?(h.mony_type, d.multi_source_code)  do 
      true -> h
      false -> match_disp_fee(drug, t)
    end
  end

  def is_match_mony_type?(mony_type, "N"), do: mony_type == "M"
  def is_match_mony_type?(mony_type, multi_source_code), do: mony_type == multi_source_code


########## END DISP FEE REGION ##########

######### START GROUP REGION ############

  defp get_group(group_num) do
    NA.DB.Repo.Groups.get_by_group_num(group_num)
    |> verify_group
  end

  defp verify_group(nil) do
    {:error, "58"}
  end

  defp verify_group(gr) do
    gr
  end
 
  def find_group_plan({:error, _rej} = rej )do
    rej
  end

  def find_group_plan(plan_info)do
    {_, group_plans} = plan_info.group
      case match_group_plan(plan_info.rx_date, group_plans)do
        {:error, _rej} = rej -> rej
        s -> Map.put(plan_info, :group_plan, s)
      end
  end
  
  defp match_group_plan(rx_date, [h|t]) do
    case date_is_active(rx_date, h.start_date, h.end_date) do
      true -> h
      false -> match_group_plan(rx_date, t)
    end
  end

  defp match_group_plan(_rx_date, []) do
    {:error, "90"}
  end


######### END GROUP REGION ##############

######### START COST REGION ##########

  defp match_cost(_drug, []) do
    IO.puts "68 cost not set"
    {:error,"68"}
  end

  defp match_cost({ drug , _}, cost_lists) do
    Enum.filter(cost_lists, fn x -> is_match_mony_type?(x.mony_type, drug.multi_source_code)end)
  end
  

######### END COST REGION ##########


########## START GENERAL REGION ##########
  
  defp process_ingredients(_service_provider, _submitted_group,_member_id, _person_code, _rx_date, _days_supply, [], results_acc, result_map) do
   sum_prices  = sum_compound_prices(results_acc, Decimal.new(0))
   lower_costs = join_prices(results_acc, " ")
   Map.put(result_map , :lower_costs,  lower_costs)
   |> Map.put(:sum_prices, sum_prices)
  end

  defp process_ingredients(service_provider,submitted_group, member_id, person_code, rx_date, days_supply, [he| ta], results, result_map)do

    case try_get_price(he.ndc, service_provider,submitted_group, member_id, person_code, rx_date, days_supply, he.quantity, he.ic, he.uc, "2")do
      {:error, _err} = err -> case he.clarification_code == "08" do
        true -> process_ingredients(service_provider, submitted_group, member_id, person_code, rx_date, days_supply, ta, [err | results], result_map)
        false -> err
      end
       p-> process_ingredients(service_provider, submitted_group, member_id, person_code, rx_date, days_supply, ta, [p.results.final_price | results], p)
    end
  end


  defp sum_compound_prices([], acc)do
    acc
  end

  defp sum_compound_prices([{price, _cb, _used_in_calc, _disp_fee}| t], acc)do
      case price do
        {:error, _err} -> sum_compound_prices(t,acc)
        _ -> sum_compound_prices(t, Decimal.add(price, acc))
      end
  end

  defp join_prices([], acc)do
    acc
  end

  defp join_prices([{price, cb, _not_used_in_calc, _disp_fee }| t], acc)do
    price =  cb <> " : " <> Decimal.to_string(price)
    acc = acc <> "," <>  price 
    
    join_prices(t, acc)
  end

  defp date_is_active(target_date, start_date, nil) do
    case compare(start_date, target_date) do
      :lt -> true
      :eq -> true
      _ -> false
    end
  end 
  
  defp date_is_active(target_date, start_date, end_date) do
    compare(start_date, target_date) in [:lt, :eq] &&
    compare(target_date, end_date) in [:lt, :eq]
  end


  def compare(date1, date2) do
    case {Date.to_erl(date1), Date.to_erl(date2)} do
      {first, second} when first > second -> :gt
      {first, second} when first < second -> :lt
      _ -> :eq
    end
  end
  
  defp get_lowest([h | t]) do
    get_lowest(t,h)
  end

  defp get_lowest([h | t] , {p, _cost_basis, _item, _dipfee} = acc) do
    
    minus_one = Decimal.new(-1)
   
    {price_element,_,_,_} = h

    if(Decimal.compare(p,price_element) == minus_one) do   
      get_lowest(t,acc)  
    else
      get_lowest(t,h) 
    end
  end
  
  defp get_lowest([], price) do
    price
  end

  defp get_highest([h | t]) do
    get_highest(t, h)
  end

  defp get_highest([h | t],{p, _cost_basis, _item, _disp_fee} = acc) do
    one = Decimal.new(1)
    
    {price_element,_,_} = h

    if(Decimal.compare(p, price_element) == one) do
      get_highest(t, h)
    else
      get_highest(t, acc)
    end
  end

  defp get_highest( [], price) do
    price
  end


########## END GENERAL REGION ########## 

end
