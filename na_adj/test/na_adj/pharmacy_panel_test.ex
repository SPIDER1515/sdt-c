defmodule NA.AdjTest.PharmacyPanel do
  use ExUnit.Case
  doctest NA.Adj
  alias NA.Adj.PharmacyPanel 
  
  test "find_matched_pharmacy_panel_item when inc_type = E, panel_list_type = P"  do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "P", inc_type: "E" , chain: nil, nabp: "0512345", start_date: start_date, end_date: end_date}
    result = PharmacyPanel.find_matched_pharmacy_panel_item([item],"0512345",nil, date)
    assert is_nil(result) 
  end

  test "find_matched_pharmacy_panel_item when inc_type = E, panel_list_type = C"  do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "C", inc_type: "E" , chain: "test-chain", nabp: nil, start_date: start_date, 
             end_date: end_date, state_code: nil}
    result = PharmacyPanel.find_matched_pharmacy_panel_item([item], nil, "test-chain", date)
    assert is_nil(result) 
  end

  test "find_matched_pharmacy_panel_item when inc_type = E, panel_list_type = N"  do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "P", inc_type: "E" , chain: nil, nabp: "0512345", start_date: start_date, end_date: end_date}
    item2 = Map.put(item, :items, [item] )
          |> Map.put(:panel_list_type, "N")
    result = PharmacyPanel.find_matched_pharmacy_panel_item([item2],"0512345",nil, date)
    assert is_nil(result) 
  end

  test "find matched item when first list of items has an exclude line as :item and the second line is the match"do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-30]
  
    item =  %{parent_id: 1, panel_list_type: "C", inc_type: "I",
              chain: "test-chain", nabp: nil, start_date: start_date,
              end_date: end_date, state_code: nil}
    item2 = %{parent_id: 3, panel_list_type: "C", inc_type: "E", 
              chain: "test-chain", nabp: nil, start_date: start_date, 
              end_date: end_date, state_code: nil}
    item3 = %{parent_id: 1, panel_id: 3, panel_list_type: "N",
              inc_type: "I", chain: "test-chain", nabp: nil,
              start_date: start_date, end_date: end_date,
              items: [item2], state_code: nil}

    result = PharmacyPanel.find_matched_pharmacy_panel_item([item3, item], nil, "test-chain", date)
    assert item === result
  end

  test "find_matched_pharmacy_panel_item when inc_type = I, panel_list_type = P"  do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "P", inc_type: "I" , chain: nil, nabp: "0512345", start_date: start_date, end_date: end_date}
    result = PharmacyPanel.find_matched_pharmacy_panel_item([item],"0512345",nil, date)
    assert result == %{chain: nil, end_date: ~D[2000-01-03], inc_type: "I", nabp: "0512345",
      panel_list_type: "P", start_date: ~D[2000-01-01]}

  end

  test "find_matched_pharmacy_panel_item when inc_type = I, panel_list_type = C"  do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "C", inc_type: "I" , chain: nil, nabp: "0512345", start_date: start_date, 
             end_date: end_date, state_code: nil}
    result = PharmacyPanel.find_matched_pharmacy_panel_item([item],"0512345",nil, date)
    assert result == %{chain: nil, end_date: ~D[2000-01-03], inc_type: "I", nabp: "0512345",
      panel_list_type: "C", start_date: ~D[2000-01-01], state_code: nil}
  end

  test "match_item when rx_date is active, panel_list_type = P and item.nabp == nabp_submited"  do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "P", chain: nil, nabp: "0512345", start_date: start_date, end_date: end_date}
    result = PharmacyPanel.match_item(item,"0512345",nil, date)
    assert result
  end
  
  test "match_item when rx_date is active, panel_list_type = P and nabp_submited starts with item.nabp*"  do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "P", chain: nil, nabp: "05*", start_date: start_date, end_date: end_date}
    result = PharmacyPanel.match_item(item,"0512345",nil, date)
    assert result
  end
 
  test "match_item when rx_date is active, panel_list_type = P and nabp_submited != pp_nabp doesnt start with item.nabp*"  do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "P", chain: nil, nabp: "0512346", start_date: start_date, end_date: end_date}
    result = PharmacyPanel.match_item(item,"0512345",nil, date)
    assert result == false
  end

  test "match_item when rx_date is active, panel_list_type = P and nabp == nil"  do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "P", chain: nil, nabp: "0512346", start_date: start_date, end_date: end_date}
    result = PharmacyPanel.match_item(item, nil, nil, date)
    assert result == false
  end

  test "match_item when rx_date is active, panel_list_type = P and nabp == \"\""  do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "P", chain: nil, nabp: "0512346", start_date: start_date, end_date: end_date}
    result = PharmacyPanel.match_item(item, nil, nil, date)
    assert result == false
  end

  test "match_item when rx_date is active, panel_list_type = P and pp_nabp == nil"  do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "P", chain: nil, nabp: nil, start_date: start_date, end_date: end_date}
    result = PharmacyPanel.match_item(item, "0112345", nil, date)
    assert result == false
  end

  test "match_item when rx_date is active, panel_list_type = P and chain_submited == item.chain and nabp_submited starts with item.nabp*"  do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "P", chain: "test-chain", nabp: "05*", start_date: start_date, end_date: end_date}
    result = PharmacyPanel.match_item(item,"0512345","test-chain", date)
    assert result
  end

  test "match_item when rx_date is active, panel_list_type = C and chain_submited == item.chain"  do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "C", chain: "test-chain", start_date: start_date,
             end_date: end_date, state_code: nil}
    result = PharmacyPanel.match_item(item,"0512345","test-chain", date)
    assert result
  end

  test "match_item when panel_list_type = C and state_code is not nil" do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "C", chain: "test-chain", start_date: start_date, 
             end_date: end_date, state_code: "02"}
    result = PharmacyPanel.match_item(item,"0512345","test-chain", date)
    expected = false
    assert result == expected
  end
  
  test "match_item when panel_list_type = C and state_code is not nil and match" do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "C", chain: "test-chain", start_date: start_date,
             end_date: end_date, state_code: "02"}
    result = PharmacyPanel.match_item(item,"0212345","test-chain", date)
    expected = true 
    assert result == expected
  end

  test "match_item when panel_list_type = C and state_code is nil and match" do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "C", chain: "test-chain", start_date: start_date,
             end_date: end_date, state_code: nil}
    result = PharmacyPanel.match_item(item,"0212345","test-chain", date)
    expected = true 
    assert result == expected
  end

  test "match_item when not match"  do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "P", chain: "test-chain-no-match", nabp: "05*", start_date: start_date, end_date: end_date};
    result = PharmacyPanel.match_item(item,"0512345","test-chain", date)
    assert !result
  end
  
  test "find_matched_pharmacy_panel_item when inc_type = E, panel_list_type = N and sub item inc_type = E and panel_list_type C should return nil and chain not matches"  do
    date = ~D[2000-01-04]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "C", inc_type: "E" , chain: "test", nabp: "0512345", start_date: start_date, 
             end_date: end_date, state_code: nil}
    item2 = %{panel_list_type: "N", inc_type: "E" , chain: "test", items: [item], nabp: "0512345", start_date: start_date,
              end_date: end_date, state_code: nil}
    result = PharmacyPanel.find_matched_pharmacy_panel_item([item2],"0512345","test-not-matches", date)
    assert is_nil(result)
  end

  test "find_matched_pharmacy_panel_item when inc_type = I, panel_list_type = N and sub item inc_type = I and panel_list_type C should return the item"  do
    date = ~D[2000-01-03]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-04]
    item = %{panel_list_type: "C", inc_type: "I" , chain: nil, nabp: "0512345", start_date: start_date,
             end_date: end_date, state_code: nil}
    item2 = %{panel_list_type: "N", inc_type: "I" , chain: "test", items: [item], nabp: "0512345", start_date: start_date,
              end_date: end_date, state_code: nil}
    result = PharmacyPanel.find_matched_pharmacy_panel_item([item2],"0512345", nil, date)
    assert item == result
  end

  test "find_matched_pharmacy_panel_item when inc_type = I, panel_list_type = N and sub item inc_type = I and panel_list_type P should return the item"  do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    item = %{panel_list_type: "P", inc_type: "I" , chain: nil, nabp: "0512345", start_date: start_date, end_date: end_date}
    item2 = %{panel_list_type: "N", inc_type: "I" , chain: "test", items: [item], nabp: "0512345", start_date: start_date, end_date: end_date}
    result = PharmacyPanel.find_matched_pharmacy_panel_item([item2],"0512345",nil, date)
    assert item == result
  end

  test "find_matched_pharmacy_panel_item multiple children tier with exclude on second tier" do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]

    p_tier_2a = %{parent_id: 3, panel_list_type: "C", inc_type: "E", chain: "test-chain", nabp: nil,
                 start_date: start_date, end_date: end_date, state_code: nil,
                 panel_id: nil, items: []}
    p_tier_2b = %{parent_id: 3, panel_list_type: "C", inc_type: "I", chain: "test-chain", nabp: nil,
                  start_date: start_date, end_date: end_date, state_code: nil,
                  panel_id: nil, items: []}
    p_tier_1 = %{parent_id: 2, panel_list_type: "N", inc_type: "I", chain: nil, nabp: nil,
                     start_date: start_date, end_date: end_date, state_code: nil,
                     panel_id: 3, items: [p_tier_2a, p_tier_2b]}
    m_tier_2a = %{parent_id: 4, panel_list_type: "C", inc_type: "I", chain: "test-chain", nabp: nil,
                  start_date: start_date, end_date: end_date, state_code: nil,
                  panel_id: nil, items: []}
    m_tier_2 = %{panel_list_type: "N", inc_type: "I", chain: nil, nabp: nil,
                 start_date: start_date, end_date: end_date, state_code: nil,
                 panel_id: 4, items: [m_tier_2a]}
    na_tier_1a = %{parent_id: 5, panel_list_type: "C", inc_type: "I", chain: "test-chain", nabp: nil,
                   start_date: start_date, end_date: end_date, state_code: nil,
                   panel_id: nil, items: []}
    parent_panel_1 = %{panel_list_type: "N", inc_type: "I", chain: nil, nabp: nil,
                     start_date: start_date, end_date: end_date, state_code: nil,
                     panel_id: 2, items: [p_tier_1, m_tier_2]}
    parent_panel_2 = %{panel_list_type: "N", inc_type: "I", chain: nil, nabp: nil,
                       start_date: start_date, end_date: end_date, state_code: nil,
                       panel_id: 5, items: [na_tier_1a]}
                
    result = PharmacyPanel.find_matched_pharmacy_panel_item([parent_panel_1, parent_panel_2],"0512345", "test-chain", date)
    assert m_tier_2a == result
  end
end
