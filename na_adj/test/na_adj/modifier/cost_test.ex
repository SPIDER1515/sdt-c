defmodule NA.ADJ.Test.Modifier.Cost do
  use ExUnit.Case, async: true

  alias NA.ADJ.Modifier.Cost

  test "Assert cost method type is lt" do
    cost = %{parent_id: 6340, auxiliary: 1, mony_type: "O", cost_method_type: "1", cost_basis: "UMAC"}
    cost2 = %{parent_id: 6340, auxiliary: 1, mony_type: "O", cost_method_type: "1", cost_basis: "I/C"}
    cost3 = %{parent_id: 6340, auxiliary: 1, mony_type: "O", cost_method_type: "1", cost_basis: "U/C"}
    cost4 = %{parent_id: 6340, auxiliary: 1, mony_type: "Y", cost_method_type: "1", cost_basis: "U/C"}
    cost_list = [cost, cost2, cost3, cost4]

    expected_result = "lt" 
    actual_result = Cost.get_cost_method_type(cost_list)
    assert expected_result == actual_result
  end

  test "Assert cost method type is gt" do
    cost = %{parent_id: 6340, auxiliary: 1, mony_type: "O", cost_method_type: "2", cost_basis: "UMAC"}
    cost2 = %{parent_id: 6340, auxiliary: 1, mony_type: "O", cost_method_type: "2", cost_basis: "I/C"}
    cost3 = %{parent_id: 6340, auxiliary: 1, mony_type: "O", cost_method_type: "2", cost_basis: "U/C"}
    cost4 = %{parent_id: 6340, auxiliary: 1, mony_type: "Y", cost_method_type: "2", cost_basis: "U/C"}
    cost_list = [cost, cost2, cost3, cost4]

    expected_result = "gt" 
    actual_result = Cost.get_cost_method_type(cost_list)
    assert expected_result == actual_result
  end

  test "Assert cost method type throws error 67" do
    cost = %{parent_id: 6340, auxiliary: 1, mony_type: "O", cost_method_type: "2", cost_basis: "UMAC"}
    cost2 = %{parent_id: 6340, auxiliary: 1, mony_type: "O", cost_method_type: "1", cost_basis: "I/C"}
    cost3 = %{parent_id: 6340, auxiliary: 1, mony_type: "O", cost_method_type: "1", cost_basis: "U/C"}
    cost4 = %{parent_id: 6340, auxiliary: 1, mony_type: "Y", cost_method_type: "2", cost_basis: "U/C"}
    cost_list = [cost, cost2, cost3, cost4]

    expected_result = {:error, "67"}
    actual_result = Cost.get_cost_method_type(cost_list)
    assert expected_result == actual_result
  end


end
