defmodule NA.AdjTest.Pharmacy do
  use ExUnit.Case
  doctest NA.Adj
  alias NA.ADJ.Pharmacy
  
  test "match_pharmacy_info on error" do
    rx_date = ~D[2000-01-01]
    error = {:error, "test"}
    result = Pharmacy.match_pharmacy_info(error, rx_date)

    assert error == result
  end

  test "match_pharmacy_info when aff list is []" do
    rx_date = ~D[2000-01-01]
    addr_l = [%{type: "1"}, %{type: "2"}]
    expected = %{affiliation_list: nil, address: %{type: "1"}}
    result = Pharmacy.match_pharmacy_info({%{}, [], addr_l}, rx_date)

    assert expected == result
  end

  test "match_pharmacy_info when aff list has a valid entry" do
    rx_date = ~D[2000-01-02]
    addr_l = [%{type: "1"}, %{type: "2"}] 
    match_al = %{start_date: ~D[2000-01-01], end_date: ~D[2000-01-03]}
    na_al = [
      %{start_date: ~D[1999-01-01], end_date: ~D[1999-01-03]},
      %{start_date: ~D[1998-01-01], end_date: ~D[1998-01-03]}
        ]
    expected = %{affiliation_list: match_al, address: %{type: "1"}}
    result = Pharmacy.match_pharmacy_info({%{}, [match_al]++ na_al, addr_l}, rx_date)

     assert expected == result
  end

  test "match_pharmacy_info when address_list is empty" do
    rx_date = ~D[2000-01-01]
    expected_aff_list = %{start_date: ~D[2000-01-01], end_date: ~D[2000-01-03]}
    na_aff_list = [
      %{start_date: ~D[1999-01-01], end_date: ~D[1999-01-03]},
      %{start_date: ~D[1998-01-01], end_date: ~D[1998-01-03]}
        ]
    expected = %{affiliation_list: nil, address: nil}
    result = Pharmacy.match_pharmacy_info({%{}, na_aff_list, []}, rx_date)

    assert expected == result
  end

end
