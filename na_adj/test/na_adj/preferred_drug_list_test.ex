defmodule NA.AdjTest.PreferredDrugList do
  use ExUnit.Case
  doctest NA.Adj
  alias NA.ADJ.PreferredDrugList, as: PDL

  test "match_pdl_drug when GPI is the match" do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    drug = %{ndc_upc_hri: "54331", gpi: "12345", id: 1}

    expected = %{value: "12345", type: "G", start_date: start_date,
                 end_date: end_date}
    na_item1 = %{value: "212345", type: "G", start_date: start_date,
                 end_date: end_date}
    na_item2 = %{value: "212345", type: "N", start_date: start_date,
                 end_date: end_date}
    na_item3 = %{value: "222345", type: "G", start_date: start_date,
                 end_date: end_date}
    result = PDL.match_pdl_drug([expected, na_item1, na_item2, na_item3], drug, date)

    assert expected == result
  end

  test "match_pdl_drug when NDC is the match" do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    drug = %{ndc_upc_hri: "12345", gpi: "232345", id: 1}

    expected = %{value: "12345", type: "N", start_date: start_date,
                 end_date: end_date}
    na_item1 = %{value: "212345", type: "G", start_date: start_date,
                 end_date: end_date}
    na_item2 = %{value: "212345", type: "N", start_date: start_date,
                 end_date: end_date}
    na_item3 = %{value: "222345", type: "G", start_date: start_date,
                 end_date: end_date}
    result = PDL.match_pdl_drug([expected, na_item1, na_item2, na_item3], drug, date)

    assert expected == result
  end

  test "match_pdl_drug when no NDC is the match" do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    drug = %{ndc_upc_hri: "no_match", gpi: "232345", id: 1}

    na_item1 = %{value: "12345", type: "N", start_date: start_date,
                 end_date: end_date}
    na_item2 = %{value: "212345", type: "G", start_date: start_date,
                 end_date: end_date}
    na_item3 = %{value: "212345", type: "N", start_date: start_date,
                 end_date: end_date}
    na_item4 = %{value: "222345", type: "G", start_date: start_date,
                 end_date: end_date}
    result = PDL.match_pdl_drug([na_item1, na_item2, na_item3, na_item4], drug, date)

    assert :no_match == result
  end

  test "match_pdl_drug when list of pdls is nil" do
    date = ~D[2000-01-02]
    start_date = ~D[2000-01-01]
    end_date = ~D[2000-01-03]
    drug = %{ndc_upc_hri: "no_match", gpi: "232345", id: 1}

    result = PDL.match_pdl_drug(nil, drug, date)

    assert :no_list = result
  end
end
