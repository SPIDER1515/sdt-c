defmodule NA.AdjTest do
  use ExUnit.Case
  doctest NA.Adj

  alias NA.Adj.Pricer

  test "the truth" do
    #:timer.sleep(10000)
    read_csv("test/na_adj/pricer/NetworkPricingFileA_100.csv")
    |> create_results_file
    |> create_headers_map
    |> write_in_file
    assert 1 + 1 == 2
    
  end

  defp read_csv(csv_path) do
    File.stream!(csv_path)
    |> Enum.into([])
  end

  defp write_in_file({headers, claims}) do
    Enum.each(claims, fn x -> test_price(x, headers) end)
  end
  
  defp create_results_file([headers|claims]) do
    File.write("test/na_adj/pricer/NetworkPricingFileA_100_result.csv","")

    {:ok,file} = File.open("test/na_adj/pricer/NetworkPricingFileA_100_result.csv",[:write])

      header = "mergecol,product_id,service_provider,rx_date,days_supply,submitted_ingredient_cost,uc,quantity, awp_effective_price,disp_fee_used,ingredient_cost_paid,cost_basis,final_price,mac price,mac_name,found_tax,calculated_tax, F508, total_timer,find_pricing_items,find_group_plan, find_plan, find_pp, find_mac_price,find_calculator,find_disp_fee_info,find_effective_price,find_cost_list,find_pricing_criteria,caculate_results,ing_1,ing_2,ing_3,ing_4,ing_5,ing_6,ing_7,ing_8,ing_9,ing_10,ing_11,ing_12,ing_13,ing_14,ing_15,ing_16,ing_17,ing_18,ing_19,ing_20,ing_21,ing_22,ing_23,ing_24, ing_25 \n"

    headers = String.replace(headers, "\n","")

    IO.binwrite(file, header)
    File.close(file)
    {headers, claims}
  end

  defp create_headers_map({headers, claims}) do
    header_index_map = String.split(headers,",")
    |>Stream.with_index(1) 
    |> Enum.reduce(%{}, fn({v,k}, acc)
      -> Map.put(acc, v, k) end)
    {header_index_map ,claims}
  end

  defp add_new_line(file) do
    IO.binwrite(file,"\r\n")
    File.close(file)
  end


  defp add_row(row) do
    {:ok,file} = File.open("test/na_adj/pricer/NetworkPricingFileA_100_result.csv",[:append])
    IO.binwrite(file, row)
    add_new_line(file)
  end

  defp test_price(original_row, headers) do
 
    original_row = String.replace(original_row, "\n","")
    |> String.replace(",.",",0.")

    original_row = Regex.replace(~r/("[^",]+),([^"]+")/, original_row, " ",global: true)
    original_row =  Regex.replace(~r/("[^",]+),"/, original_row, " ",global: true)
 
    claim = String.split(original_row,",")

    row = [Enum.at(claim,headers["F333"]-1)]
    
    product_id = String.pad_leading(Enum.at(claim, headers["F407"]-1), 11,"0") 
    row = row ++ [product_id]

    service_provider = String.pad_leading(Enum.at(claim,headers["F201"]-1),7,"0")
    row = row ++ [service_provider]
    
    rx_date = NA.Shared.DateParser.parse(Enum.at(claim,headers["F401"]-1),"dd-mmm-yyyy")
    row = row ++ [Enum.at(claim,headers["F401"]-1)]

    days_supply = String.to_integer(String.replace(Enum.at(claim, headers["F405"]-1),"-",""))
    row = row ++ [Enum.at(claim,headers["F405"]-1)]
   
    member_id = Enum.at(claim,headers["F302"]-1)
    
    person_code = Enum.at(claim, headers["F303"]-1)

    merge_col = Enum.at(claim, headers["Mergecol"]-1)
    group_num_used = String.split(Enum.at(claim, headers["F390"]-1), ":")
      |> Enum.at(1)
    
    {ic, _} = Float.parse(String.replace(Enum.at(claim,headers["F409"]-1),"-",""))
    
    row = row ++ [String.replace(Enum.at(claim,headers["F409"]-1),"-","")]

    {uc, _} = Float.parse(String.replace(Enum.at(claim,headers["F426"]-1),"-",""))
    row = row ++ [Enum.at(claim,headers["F426"]-1)]

    {quantity, _} = Float.parse(String.replace(Enum.at(claim,headers["F442"]-1),"-",""))
    quantity = quantity /1000 |> Float.to_string
     
    row = row ++ [quantity]

    compound_code = Enum.at(claim, headers["F406"]-1)
    ingredients_info = get_claim_ingredients(claim, headers, compound_code)

    results_map = case (compound_code =="2") do
        true -> Pricer.get_compound_price(service_provider,group_num_used, member_id, person_code, rx_date, days_supply, ingredients_info)
        false -> Pricer.try_get_price(product_id, service_provider,group_num_used,  member_id, person_code, rx_date, days_supply, quantity, ic, uc, compound_code)
      end
    {price, cb, _, disp_fee} = case results_map do
      {:error, _rej} -> {Decimal.new(0), "N/A", "N/A", Decimal.new(0)}
      s -> s.results.final_price
    end

    price = case compound_code do
      "2" -> case results_map do 
            {:error, _err }-> Decimal.new(0) 
            _ -> results_map.sum_prices
        end
      _ -> price
    end

    effective_price = case results_map do
      {:error, _rtt} -> Decimal.new(0)
      s -> s.results.final_eff
    end
    add_info = case results_map do
      {:error, err} -> err
        _ -> " " 
    end

    mac_price = case results_map do
      {:error, _err} -> nil  
        s -> s.results.mac_price
    end

    addi_drugs_prices =  case compound_code do
      "2" -> case results_map do
            {:error, _rej} -> " " 
            s -> s.lower_costs
      end
      _ -> " "
    end 

    row = row ++ [Decimal.to_string(effective_price)]
    
    disp_fee = case cb do
      "U/C" -> Decimal.new(0)
      _ -> disp_fee
    end

    row = row ++ [Decimal.to_string(disp_fee)]

    ingredient_cost_paid = Decimal.to_string(Decimal.sub(Decimal.round(price,2), disp_fee))
    row = row ++ [ingredient_cost_paid]
    
    row = row ++ [cb]

    row = row ++ [Decimal.to_string(Decimal.round(price,2))]

    m_price = case mac_price do
      nil -> Decimal.new(0)
      m -> m.price
    end
    row = row ++ [Decimal.to_string(m_price)]

    m_name = case mac_price do
      nil -> "N/A"
      m -> m.mac_name
    end
    
    row = row ++ [m_name]
    
    found_tax = case results_map do
      {:error, _rej} -> "0"
      s -> s.found_tax
    end

    row = row ++ [found_tax]
    pharmacy_tax = case results_map do
      {:error, _rej} -> "0"
      s -> Decimal.to_string(s.pharmacy_tax)
    end

    row = row ++ [pharmacy_tax]
    
    row = row ++ [Enum.at(claim, headers["F508"]-1)]
   
    row_to_add = Enum.join(row,",")
    ind_timers = case results_map do
      {:error, _err} -> " "
      _ -> Enum.join([to_string(results_map.find_pricing_items) ,",",to_string(results_map.find_group_plan),",",to_string(results_map.find_plan),",",to_string(results_map.find_pharmacy_panel) ,",",to_string(results_map.find_mac_price),",",to_string(results_map.find_calculator),",",to_string(results_map.find_disp_fee_info),",",to_string(results_map.find_effective_price),",",to_string(results_map.find_cost_list),",",to_string(results_map.find_pricing_criteria),",",to_string(results_map.calculate_results)])
    end

    total_timer = case results_map do
      {:error, _err} -> " "
      s -> to_string((s.find_pricing_items + s.find_group_plan + s.find_plan + s.find_pharmacy_panel + s.find_mac_price + s.find_calculator + s.find_disp_fee_info + s.find_effective_price + s.find_cost_list + s.find_pricing_criteria + s.calculate_results)/1000000)
    end

    row_to_add = row_to_add <>"," <> to_string(total_timer) <>" secs" <> "," <>ind_timers <> addi_drugs_prices
    add_row(row_to_add)
  end
  
  defp get_claim_ingredients(_claim, _headers, cc) when cc == "1" do
    []
  end
    
  defp get_claim_ingredients(claim, headers, compound_code) when compound_code == "2" do
    {ingredient_count, _} = Integer.parse(Enum.at(claim, headers["F447"]-1))
    ingredients_map_list_get(claim, headers, ingredient_count-1, [])
  end

  defp ingredients_map_list_get(claim, headers, ingredient_count, result)do
    it = Enum.count(result)
    f490 = Enum.at(claim, headers["F490"]-1 + it)
    {submitted_uc, _} = Float.parse(Enum.at(claim, headers["F426"]-1))
    {comp_ing_cost, _}= Float.parse(Enum.at(claim, headers["F449"]-1 + it))
    {submitted_ic, _} = Float.parse(Enum.at(claim, headers["F409"]-1))
    case it == ingredient_count do
    true -> result
    false ->
      ndc = String.pad_leading(Enum.at(claim, headers["F489"]-1 + it), 11,"0") 
      {qty, _} = Float.parse(String.replace(Enum.at(claim,headers["F448"]-1 + it),"-",""))
      qty = qty/1000 |> Float.to_string
      ic = case f490 do
        "07" -> get_ic_compound_07(submitted_uc, comp_ing_cost, submitted_ic)
        _ -> Enum.at(claim, headers["F449"]-1 + it)
      end
      uc = 
        case f490 do
        "07" -> Enum.at(claim, headers["F449"]-1 + it)
          _  -> get_uc_compound_non_07(submitted_uc, comp_ing_cost, submitted_ic)
        end
      clarification_code = case Enum.at(claim, headers["F420"]-1) == "08" do
       true -> "08"
       false -> case Enum.at(claim, headers["F420101"]-1) do
         "08" -> "08"
         _-> "01"
       end
     end
     curr = %{ndc: ndc, quantity: qty, ic: ic, clarification_code: clarification_code, uc: uc}
     ingredients_map_list_get(claim, headers, ingredient_count, [curr| result])
    end
  end
  
  defp get_ic_compound_07(submitted_uc, comp_ing_cost, submitted_ic)do
    submitted_ic/(submitted_uc/comp_ing_cost)
    |> Float.to_string
  end

  defp get_uc_compound_non_07(submitted_uc, comp_ing_cost, submitted_ic)do
    submitted_uc/(submitted_ic/comp_ing_cost)
    |> Float.to_string
  end

  defp decode_reject(add_info) do
    case add_info do
      "54" -> "Invalid Product ID"
      "99" -> "Pharmacy not contracted"
      "98" -> "No calculator Match"
      "77" -> "Discontinued"
      "79" -> "No Valid Plan BL_list"
      "69" -> "No cost found"
      "68" -> "costlist not set"
      "67" -> "mismatched costlist optionType"
      "66" -> "no planset"
      "65" -> "no group plan"
      "64" -> "no pharmacy panel on this id"
      "63" -> "No pharmacy panel item"
      "62" -> "no effective price"
      "61" -> "Invalid provider ID"
      "60" -> "No Disp_fee for ID"
      "59" -> "No match disp fee"
      "58" -> "Group Not Found"
      "57" -> "No Group Plan"
      "56" -> "No prices set"
      "49" -> "Patient Not Eligible"
       s -> s
    end
  end
end

