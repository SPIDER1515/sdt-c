defmodule NA.AdjTest.Patient.Groups do
  use ExUnit.Case
  doctest NA.Adj

  alias NA.DB.Schema.Groups, as: G
  alias NA.DB.Schema.Patient, as: P
  alias NA.DB.Schema.Patient_eligibility_list, as: PEL
  alias NA.ADJ.Patient.DeterminationResponse, as: DR
 
  test "assert valdate_groups if there is only one patient then just return the structure" do
    r = %DR{patients: [%P{patient_num: "123"}]}
    result = NA.ADJ.Patient.Groups.validate_groups(r)
    assert result == r 
  end

  test "assert valdate_groups if there are no patients return the structure" do
    r = %DR{patients: []}
    result = NA.ADJ.Patient.Groups.validate_groups(r)
    assert result == r 
  end

  test "assert valdate_groups if there are many patients and a submitted group then just return the structure" do
    r = %DR{patients: [%P{patient_num: "123"}, %P{patient_num: "1234"}], submitted_group: %G{id: 1}}
    result = NA.ADJ.Patient.Groups.validate_groups(r)
    assert result == r 
  end

  test "assert valdate_groups if there are many patients and no submitted group and all elig line matches then just return the structure" do
    r = %DR{patients: [
        {%P{patient_num: "123"}, [%PEL{group_id: 1}]}, 
        {%P{patient_num: "123"}, [%PEL{group_id: 1}]}], 
      submitted_group: nil}
    result = NA.ADJ.Patient.Groups.validate_groups(r)
    assert result == r 
  end
  
  test "assert valdate_groups if there are many patients one with no elig lines and no submitted group and all elig line matches then just return the structure" do
    r = %DR{patients: [
      {%P{}, nil}, 
      {%P{}, [%PEL{group_id: 1}]},
      {%P{}, nil},
      {%P{}, [%PEL{group_id: 1}]}
      ], submitted_group: nil}
    result = NA.ADJ.Patient.Groups.validate_groups(r)
    assert result == r 
  end

  test "assert valdate_groups if there are many patients and no submitted group and 1 elig line not matches then just return 06 reject_code" do
    r = %DR{patients: [
      {%P{patient_num: "123"}, [%PEL{group_id: 1}]}, 
      {%P{patient_num: "1234"},[%PEL{group_id: 2}]}], 
      submitted_group: nil}
    result = NA.ADJ.Patient.Groups.validate_groups(r)
    assert result.reject_code == "06"
  end

  test "assert valdate_groups if there are many patients and no submitted group and there is not elig_lines in any patients then just return N1 reject_code" do
    r = %DR{patients: [
      {%P{}, nil}, 
      {%P{}, nil}],
      submitted_group: nil}
    result = NA.ADJ.Patient.Groups.validate_groups(r)
    assert assert result.reject_code == "N1"
  end
end