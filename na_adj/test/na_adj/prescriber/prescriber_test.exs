defmodule NA.AdjTest.Prescriber.Prescriber do
  use ExUnit.Case
  alias NA.ADJ.Prescriber.Prescriber

  test "test valid npi check_num" do
    npi = "1234567893"
    result = Prescriber.is_npi_checksum?(npi)
    expected = true

    assert expected === result
  end

  test "test invalid npi check_num" do
    npi = "1234567892"
    result = Prescriber.is_npi_checksum?(npi)
    expected = false

    assert expected === result
  end

  test " test valid match numeric pattern" do
    npi = "1234567890"
    result =  Prescriber.is_npi?(npi)
    expected = true

    assert expected == result
  end
  
  test " test invalid match numeric pattern too short" do
    npi = "1234560"
    result =  Prescriber.is_npi?(npi)
    expected = false 

    assert expected == result
  end

  test " test invalid match numeric pattern too large" do
    npi = "12345601234564"
    result =  Prescriber.is_npi?(npi)
    expected = false 

    assert expected == result
  end
 
  test " test invalid match numeric pattern non all digits" do
    npi = "123456A890"
    result =  Prescriber.is_npi?(npi)
    expected = false 

    assert expected == result
  end

  test "test invalid match numeric pattern empty" do
    npi = ""
    result = Prescriber.is_npi?(npi)
    expected = false 

    assert expected == result
  end

  test "test invalid dea not 2 letters start" do
    dea = "0012345"
    result = Prescriber.is_dea?(dea)
    expected = false

    assert expected === result
  end

  test "test invalid dea too short number identifier" do
    dea = "AA12345"
    result = Prescriber.is_dea?(dea)
    expected = false

    assert expected === result
  end

  test "test invalid dea more than 2 letters start" do
    dea = "AAA12345"
    result = Prescriber.is_dea?(dea)
    expected = false

    assert expected === result
  end

  test "test valid dea" do
    dea = "AA1234567"
    result = Prescriber.is_dea?(dea)
    expected = true

    assert expected === result
  end

end
