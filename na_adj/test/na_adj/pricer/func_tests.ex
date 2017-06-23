defmodule NA.ADJ.Test.Pricer.FuncTests do
  use ExUnit.Case, async: true

  test "Assert mony type is same as multi source code" do
    mony_type = "Y"
    multi_source_code = "Y"
    expected_result = true
    actual_result = NA.Adj.Pricer.is_match_mony_type?(mony_type, multi_source_code)
    assert expected_result == actual_result
  end

  test "Assert multi source code M is converted to N for comparison" do
    mony_type = "M"
    multi_source_code = "N"
    expected_result = true
    actual_result = NA.Adj.Pricer.is_match_mony_type?(mony_type, multi_source_code)
    assert expected_result == actual_result
  end

  test "Assert multi source code and mony type assertion fails" do
    mony_type = "O"
    multi_source_code = "N"
    expected_result = false
    actual_result = NA.Adj.Pricer.is_match_mony_type?(mony_type, multi_source_code)
    assert expected_result == actual_result
  end

end

