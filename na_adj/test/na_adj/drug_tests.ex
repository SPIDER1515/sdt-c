defmodule NA.AdjTest.Drug do
  use ExUnit.Case
  doctest NA.Adj

  alias NA.ADJ.Drug

  test "test find_effective_price when a drug price is match" do
    date = ~D[2000-01-02]
    items = [
      %{price_effective_date: ~D[2001-01-01], price_code: "A"},
      %{price_effective_date: ~D[2002-01-01], price_code: "A"},
      %{price_effective_date: ~D[2000-01-01], price_code: "B"}
      ]
    expected = %{price_effective_date: ~D[2000-01-01], price_code: "A"}
    result = Drug.find_effective_price({"test_drug", items ++ [expected]}, date) 
    assert expected == result.effective_price
  end

  test "test find_effective_price when no drug price is match" do
    date = ~D[1999-01-02]
    items = [
      %{price_effective_date: ~D[2001-01-01], price_code: "A"},
      %{price_effective_date: ~D[2002-01-01], price_code: "A"},
      %{price_effective_date: ~D[2000-01-01], price_code: "B"}
      ]
    result = Drug.find_effective_price({"test_drug", items}, date)
    expected = {:error, "95"}
    assert result == expected
  end

end
