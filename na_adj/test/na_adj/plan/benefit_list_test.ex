defmodule NA.ADJ.Test.Plan.BenefitList do
  use ExUnit.Case, async: true

  alias NA.ADJ.Plan.BenefitList

  test "Assert benefit item type F" do
    bl_item = %{benefit_item_type: "F"}
    compound_code = "2"
    days_supply = nil
    drug = nil

    actual_result = BenefitList.valid?(bl_item, days_supply, 
                                              drug, compound_code)
    assert actual_result
  end

  test "Assert benefit item type N" do
    bl_item = %{benefit_item_type: "N", ndc:  "00002120001"}
    compound_code = nil
    days_supply = nil
    drug_item = %{ndc_upc_hri: "00002120001"}
    drug = {drug_item, nil}

    actual_result = BenefitList.valid?(bl_item, days_supply, 
                                              drug, compound_code)
    assert actual_result
  end

  test "Assert benefit item type V where days supply is lower than value_ds" do
    bl_item = %{benefit_item_type: "V", value_ds:  "84+"}
    compound_code = nil
    days_supply = 30
    drug = nil

    actual_result = BenefitList.valid?(bl_item, days_supply, 
                                              drug, compound_code)
    assert actual_result == false
  end

  test "Assert benefit item type V where days supply is higher than value_ds" do
    bl_item = %{benefit_item_type: "V", value_ds:  "84+"}
    compound_code = nil
    days_supply = 90
    drug = nil

    actual_result = BenefitList.valid?(bl_item, days_supply, 
                                              drug, compound_code)
    assert actual_result
  end

  test "Assert benefit item type A" do
    bl_item = %{benefit_item_type: "A"}
    compound_code = nil
    days_supply = nil
    drug = nil

    actual_result = BenefitList.valid?(bl_item, days_supply, 
                                              drug, compound_code)
    assert actual_result
  end

  test "Assert empty benefit item" do
    bl_item = %{}
    compound_code = nil
    days_supply = nil
    drug = nil

    actual_result = BenefitList.valid?(bl_item, days_supply, 
                                              drug, compound_code)
    assert actual_result == false
  end

  test "Assert benefit list list is true for item type A" do
    bl_item = %{benefit_item_type: "F"}
    bl_item2 = %{benefit_item_type: "N"}
    bl_item3 = %{benefit_item_type: "A"}
    bl_list = [bl_item, bl_item2, bl_item3]
    compound_code = nil
    days_supply = nil
    drug = nil

    actual_result = BenefitList.validate_list(bl_list, days_supply, 
                                              drug, compound_code)
    assert actual_result
  end
end
