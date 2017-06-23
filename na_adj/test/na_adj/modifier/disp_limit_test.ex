defmodule NA.ADJ.Test.Modifier.DispLimit do
  use ExUnit.Case, async: true

  alias NA.ADJ.Modifier.DispLimit, as: DL
  
  test "match_item where auxiliary = standard not maintenance" do
    na_items = [%{auxiliary: "4", mony: "Y"} , %{auxiliary: "2", mony: "O"}]
    expected = %{auxiliary: "1", mony: "Y"}
    preferred = false
    maintenance = false
    result = DL.validate_items(na_items++[expected], "Y", maintenance, preferred)

    assert expected == result
  end

  test "match_item where auxiliary: 2 preffered true and maint false" do
    na_items = [%{auxiliary: "4", mony: "Y"}, %{auxiliary: "2", mony: "O"}]
    expected = %{auxiliary: "2", mony: "Y"}
    preferred = true 
    maintenance = false
    result = DL.validate_items(na_items++[expected], "Y", maintenance, preferred)

    assert expected == result
  end

  test "match_item where auxiliary: 3 preferred false and maint true" do
    na_items = [%{auxiliary: "4", mony: "Y"}, %{auxiliary: "2", mony: "O"}]
    expected = %{auxiliary: "3", mony: "Y"}
    preferred = false
    maintenance = true
    result = DL.validate_items(na_items++[expected], "Y", maintenance, preferred)

    assert expected == result
  end

  test "match_item where auxiliary: 4 prefferred true and maint true" do
    na_items = [%{auxiliary: "3", mony: "Y"}, %{auxiliary: "2", mony: "Y"}]
    expected = %{auxiliary: "4", mony: "Y"}
    preferred = true
    maintenance = true
    result = DL.validate_items(na_items++[expected], "Y", maintenance, preferred)

    assert expected == result
  end

  test "match_item where there is no item match" do
    na_items = [%{auxiliary: "3", mony: "Y"}, 
                %{auxiliary: "2", mony: "Y"},
                %{auxiliary: "4", mony: "Y"}]
    preferred = true
    maintenance = true
    result = DL.validate_items(na_items, "O", maintenance, preferred)

    assert is_nil(result)
  end

end
