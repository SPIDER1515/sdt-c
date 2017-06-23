defmodule NA.ADJ.Test.Modifier.DispFee do
  use ExUnit.Case, async: true

  alias NA.ADJ.Modifier.DispFee

  test "Assert disp fee applies when cost list is zero" do
    disp_fee = %{fee: Decimal.new(7000.00)}
    cost_list_fee = Decimal.new(0)
    expected_result = Decimal.new(7000.00)
    actual_result = DispFee.get_disp_fee_to_apply(disp_fee, cost_list_fee)
    assert expected_result == actual_result 
  end

  test "Assert cost list fee applies when it is greater than zero" do
    disp_fee = %{fee: Decimal.new(7000.00)}
    cost_list_fee = Decimal.new(7100.00)
    expected_result = Decimal.new(7100.00)
    actual_result = DispFee.get_disp_fee_to_apply(disp_fee, cost_list_fee)
    assert expected_result == actual_result 
  end

end
