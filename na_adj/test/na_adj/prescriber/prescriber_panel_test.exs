defmodule NA.Adj.Test.Precriber.PanelTest do
  
  use ExUnit.Case
  alias NA.Adj.Prescriber.Panel
  alias NA.DB.Schema.PrescriberPanelItem, as: PPI

  test "Assert match item by npi when list type is P" do
    items = [%PPI{panel_list_type: "P", npi: "123", dea: "1234", start_date: ~D[2016-01-01], end_date: ~D[2018-01-01] }]
    result =  Panel.match_prescriber_panel_items(items, ~D[2017-01-01], "123", "1235")
    assert result.npi == "123"
  end

  test "Assert not match item by npi when list type is P" do
    items = [%PPI{panel_list_type: "P", npi: "123", dea: "1234", start_date: ~D[2016-01-01], end_date: ~D[2018-01-01] }]
    result =  Panel.match_prescriber_panel_items(items, ~D[2017-01-01], "xx", "xxxx")
    assert is_nil(result)
  end

  test "Assert match item by dea when list type is not P" do
    items = [%PPI{panel_list_type: "C", npi: "123", dea: "1234", start_date: ~D[2016-01-01], end_date: ~D[2018-01-01] }]
    result =  Panel.match_prescriber_panel_items(items, ~D[2017-01-01], "1235", "1234")
    assert result.dea == "1234"
  end

  test "Assert not match item by dea when list type is not P" do
    items = [%PPI{panel_list_type: "C", npi: "123", dea: "1234", start_date: ~D[2016-01-01], end_date: ~D[2018-01-01] }]
    result =  Panel.match_prescriber_panel_items(items, ~D[2017-01-01], "XX", "XX")
    assert is_nil(result)
  end
end
