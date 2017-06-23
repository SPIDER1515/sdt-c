defmodule NA.ADJ.Test.Modifier.Copay do
  use ExUnit.Case, async: true
  doctest NA.ADJ.Modifiers.Copay

  alias NA.ADJ.Modifiers.Copay

  test "Match copay list" do
    copays = [%{auxiliary: 1, mony_type: "M", copay_basis: "D"}]
    auxiliary = 1
    mony_type = "M"
    copay_basis = "D"

    result = Copay.match_copay_list(copays, auxiliary, mony_type, copay_basis)
    assert copays == result
  end

  test "Match copay with several" do
    copays = [%{auxiliary: 1, mony_type: "M", copay_basis: "D", tier_max: 30},
              %{auxiliary: 1, mony_type: "M", copay_basis: "D", tier_max: 60},
              %{auxiliary: 1, mony_type: "M", copay_basis: "D", tier_max: 90}]
    auxiliary = 1
    mony_type = "M"
    copay_basis = "D"

    result = Copay.match_copay_list(copays, auxiliary, mony_type, copay_basis)

    assert copays == result
  end
  
  test "Assert copay matches to second tier" do
    copays = [%{auxiliary: 1, mony_type: "M", copay_basis: "D", tier_max: 30},
              %{auxiliary: 1, mony_type: "M", copay_basis: "D", tier_max: 60},
              %{auxiliary: 1, mony_type: "M", copay_basis: "D", tier_max: 90}]
    ds = 36
    qty = 0
    ingr_disp_tax = 0
    cost = 0
    result = Copay.validate_matched_copay(copays, ds, qty, ingr_disp_tax, cost)

    assert result == %{auxiliary: 1, mony_type: "M", copay_basis: "D", tier_max: 60}
  end


  test "Assert copay matches to first tier" do
    copays = [%{auxiliary: 1, mony_type: "M", copay_basis: "D", tier_max: 30},
              %{auxiliary: 1, mony_type: "M", copay_basis: "D", tier_max: 60},
              %{auxiliary: 1, mony_type: "M", copay_basis: "D", tier_max: 90}]
    ds = 25
    qty = 0
    ingr_disp_tax = 0
    cost = 0
    result = Copay.validate_matched_copay(copays, ds, qty, ingr_disp_tax, cost)

    assert result == %{auxiliary: 1, mony_type: "M", copay_basis: "D", tier_max: 30}
  end

  test "Assert copay matches to third tier" do
    copays = [%{auxiliary: 1, mony_type: "M", copay_basis: "I", tier_max: 30},
              %{auxiliary: 1, mony_type: "M", copay_basis: "I", tier_max: 60},
              %{auxiliary: 1, mony_type: "M", copay_basis: "I", tier_max: 90}]
    ds = 0
    qty = 0
    ingr_disp_tax = 88
    cost = 0
    result = Copay.validate_matched_copay(copays, ds, qty, ingr_disp_tax, cost)

    assert result == %{auxiliary: 1, mony_type: "M", copay_basis: "I", tier_max: 90}
  end

  test "Assert no copay matches" do
    copays = [%{auxiliary: 1, mony_type: "M", copay_basis: "D", tier_max: 30},
              %{auxiliary: 1, mony_type: "M", copay_basis: "D", tier_max: 60},
              %{auxiliary: 1, mony_type: "M", copay_basis: "D", tier_max: 90}]
    ds = 100
    qty = 0
    ingr_disp_tax = 0
    cost = 0
    result = Copay.validate_matched_copay(copays, ds, qty, ingr_disp_tax, cost)

    assert result == {:error, "No copay match"}
  end

  test "Assert copay matches to third tier with C copay basis" do
    copays = [%{auxiliary: 1, mony_type: "M", copay_basis: "C", tier_max: 30},
              %{auxiliary: 1, mony_type: "M", copay_basis: "C", tier_max: 60},
              %{auxiliary: 1, mony_type: "M", copay_basis: "C", tier_max: 90}]
    ds = 0
    qty = 0
    ingr_disp_tax = 0
    cost = 88
    result = Copay.validate_matched_copay(copays, ds, qty, ingr_disp_tax, cost)

    assert result == %{auxiliary: 1, mony_type: "M", copay_basis: "C", tier_max: 90}
  end

  test "Assert calculation type 01 min $$$ only when drug cost is lower than min dollars amount" do
    copay = %{calculation_type: 01, fee_numeric: 15}
    drug_cost = 11.43
    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 11.43
  end

  test "Assert calculation type 01 min $$$ only when drug cost is higher than min dollars amount" do
    copay = %{calculation_type: 01, fee_numeric: 15}
    drug_cost = 15.43
    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 15
  end

  test "Assert calculation type 02 percent only" do
    copay = %{calculation_type: 02, percent: 50}
    drug_cost = 278.13

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 139.07
  end

  test "Assert calculation type 03 min $$$ plus percent is zero" do
    copay = %{calculation_type: 03, fee_numeric: -50 , percent: 100}
    drug_cost = 6.25

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 0.00
  end

  test "Assert calculation type 03 min $$$ plus percent returns correct amount" do
    copay = %{calculation_type: 03, fee_numeric: -50 , percent: 100}
    drug_cost = 53.10

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 3.10
  end

  test "Assert calculation type 04 lesser of max $ and percent returns the percent of the drug cost" do
    copay = %{calculation_type: 04, max_fee: 145, percent: 30}
    drug_cost = 247.16

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 74.15
  end

  test "Assert calculation type 04 lesser of max $ and percent returns the max fee" do
    copay = %{calculation_type: 04, max_fee: 145, percent: 30}
    drug_cost = 1000.00

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 145
  end

  test "Assert calculation type 05 greater of min $$$ and percent returns the percent of the drug cost" do
    copay = %{calculation_type: 05, fee_numeric: 45, percent: 20}
    drug_cost = 291.94

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 58.39
  end

  test "Assert calculation type 05 greater of min $ and percent returns the min fee" do
    copay = %{calculation_type: 05, fee_numeric: 45, percent: 20}
    drug_cost = 150.15

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 45
  end

  test "Assert calculation type 06 min $$$ plus net percentage returns correct amount" do
    copay = %{calculation_type: 06, fee_numeric: 35, percent: 10}
    drug_cost = 310.55

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 62.56
  end

  test "Assert a second test for calculation type 06 min $$$ plus net percentage returns correct amount" do
    copay = %{calculation_type: 06, fee_numeric: 35, percent: 20}
    drug_cost = 310.55

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 90.11
  end

  test "Assert calculation type 07 percent between min and max returns the percent of the drug cost" do
    copay = %{calculation_type: 07, fee_numeric: 20, max_fee: 100, percent: 10}
    drug_cost = 940.20

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 94.02
  end

  test "Assert calculation type 07 percent between min and max returns the percent of drug cost not inflated to min" do
    copay = %{calculation_type: 07, fee_numeric: 10, max_fee: 50, percent: 10}
    drug_cost = 8.34

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 8.34
  end

  test "Assert calculation type 07 percent between min and max returns the min fee" do
    copay = %{calculation_type: 07, fee_numeric: 10, max_fee: 50, percent: 10}
    drug_cost = 11.34

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 10.00
  end

  test "Assert a second test for calculation type 07 percent between min and max returns the min fee" do
    copay = %{calculation_type: 07, fee_numeric: 10, max_fee: 50, percent: 10}
    drug_cost = 38.32

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 10.00
  end

  test "Assert calculation type 07 percent between min and max returns the max fee" do
    copay = %{calculation_type: 07, fee_numeric: 10, max_fee: 50, percent: 10}
    drug_cost = 525.41

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 50.00
  end

  test "Assert calculation type 08 tp > max ? percent : min $$$ returns min fee" do
    copay = %{calculation_type: 08, fee_numeric: 12.50, max_fee: 750, percent: 25}
    drug_cost = 106.22

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 12.50
  end

  test "Assert calculation type 08 tp > max ? percent : min $$$ returns calculated copay" do
    copay = %{calculation_type: 08, fee_numeric: 12.50, max_fee: 750, percent: 25}
    drug_cost = 849.73

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 212.43
  end

  test "Assert calculation type 09 min $$$ + (PCT * MAX(TP-MAX, 0)) returns min fee" do
    copay = %{calculation_type: 09, fee_numeric: 100, max_fee: 750, percent: 100}
    drug_cost = 212.43

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 100
  end

  test "Assert calculation type 09 min $$$ + (PCT * MAX(TP-MAX, 0)) returns the calculated copay" do
    copay = %{calculation_type: 09, fee_numeric: 100, max_fee: 750, percent: 100}
    drug_cost = 3930.00

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 3280.00
  end

  test "Assert a second test for calculation type 09 min $$$ + (PCT * MAX(TP-MAX, 0)) returns the calculated copay" do
    copay = %{calculation_type: 09, fee_numeric: 80, max_fee: 750, percent: 80}
    drug_cost = 3930.00

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 2624.00
  end

  test "Assert calculation type 10 min + (pct * max(tp-max-min, 0)) returns min fee" do
    copay = %{calculation_type: 10, fee_numeric: 15, max_fee: 100, percent: 100}
    drug_cost = 106.22

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 15
  end

  test "Assert calculation type 10 min + (pct * max(tp-max-min, 0)) returns the calculated copay" do
    copay = %{calculation_type: 10, fee_numeric: 15, max_fee: 100, percent: 50}
    drug_cost = 212.43

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 63.72
  end

  test "Assert calculation type 11 (tp > $pct) ? $max : $min) returns the max fee" do
    copay = %{calculation_type: 11, fee_numeric: 15, max_fee: 25, percent: 100}
    drug_cost = 435.45

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 25.00
  end

  test "Assert calculation type 11 (tp > $pct) ? $max : $min) returns the min fee" do
    copay = %{calculation_type: 11, fee_numeric: 15, max_fee: 25, percent: 100}
    drug_cost = 73.83

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 15.00
  end

  test "Assert calculation type 14 min $ plus percent up to max $ returns total cost as copay" do
    copay = %{calculation_type: 14, fee_numeric: 50, max_fee: 300, percent: 5}
    drug_cost = 589.96

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 79.50
  end

  test "Assert calculation type 14 min $ plus percent up to max $ returns non inflated drug cost amount" do
    copay = %{calculation_type: 14, fee_numeric: 50, max_fee: 300, percent: 5}
    drug_cost = 17.38

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 17.38
  end

  test "Assert calculation type 16 (tp > max) ? min $$$ : percent returns min fee" do
    copay = %{calculation_type: 16, fee_numeric: 10, max_fee: 300, percent: 30}
    drug_cost = 988.24

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 10
  end

  test "Assert calculation type 16 (tp > max) ? min $$$ : percent returns calculated copay" do
    copay = %{calculation_type: 16, fee_numeric: 10, max_fee: 300, percent: 30}
    drug_cost = 3.1

    result = Copay.calculate_copay(copay, drug_cost)

    assert result == 0.93
  end

end
