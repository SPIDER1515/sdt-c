defmodule NA.AdjTest.PharmacyPanel do
  use ExUnit.Case
  doctest NA.Adj
  alias NA.ADJ.Patient.Determination
  alias NA.DB.Schema.Patient_eligibility_list, as: PEL
  alias NA.DB.Schema.Patient, as: P
  alias NA.DB.Schema.Groups, as: G
  alias NA.ADJ.Patient.DeterminationResponse, as: DR

  test "assert find_active_eligibility_line just has 1 active and group matches submitted one" do
    dt = %DR{
      matched_patient: {%P{patient_num: "123"}, [%PEL{start_date: ~D[2016-01-01], end_date: ~D[2018-01-01], group_id: 1},
        %PEL{start_date: ~D[2016-01-01], end_date: ~D[2016-01-02], group_id: 1}]},
      submitted_rx_date: ~D[2017-01-01],
      submitted_group: {%G{id: 1}, []}}
    result = Determination.find_active_eligibility_line(dt)
    {p,_} = result.matched_patient
    assert result.match  && p.patient_num == "123" && result.reject_code == ""
  end  

  test "assert find_active_eligibility_line has more than 1 active and group not matches submitted one" do
    dt = %DR{
      matched_patient: {%P{patient_num: "123"}, [%PEL{start_date: ~D[2016-01-01], end_date: ~D[2018-01-01], group_id: 1},
        %PEL{start_date: ~D[2016-01-01], end_date: ~D[2018-01-01], group_id: 1}]},
      submitted_rx_date: ~D[2017-01-01],
      submitted_group: {%G{id: 1}, []}}
    result = Determination.find_active_eligibility_line(dt)
    assert !result.match  &&  result.reject_code == "99"
  end  

  test "assert find_active_eligibility_line has not an active line and group not matches submitted one" do
    dt = %DR{
      matched_patient: {%P{patient_num: "123"}, [%PEL{start_date: ~D[2016-01-01], end_date: ~D[2016-02-01], group_id: 1},
        %PEL{start_date: ~D[2016-01-01], end_date: ~D[2016-02-01], group_id: 1}]},
      submitted_rx_date: ~D[2017-01-01],
      submitted_group: {%G{id: 1}, []}}
    result = Determination.find_active_eligibility_line(dt)
    assert !result.match  &&  result.reject_code == "600"
  end  
  
  test "assert match_exact_dob when matches" do
    p = [{%P{patient_num: "123", date_of_birth: ~D[2017-01-01]}, []},
        {%P{patient_num: "1234", date_of_birth: ~D[2017-01-02]}, []},
        {%P{patient_num: "1235", date_of_birth: ~D[2017-01-03]}, []}]
    dob = ~D[2017-01-02]
    {p, _} = Determination.match_exact_dob(p, dob)
    assert p.patient_num == "1234"
  end  

  test "assert match_exact_dob when not matches" do
    p = [{%P{patient_num: "123", date_of_birth: ~D[2017-01-01]}, []},
        {%P{patient_num: "1234", date_of_birth: ~D[2017-01-02]}, []},
        {%P{patient_num: "1235", date_of_birth: ~D[2017-01-03]}, []}]
    dob = ~D[2017-01-04]
    result = Determination.match_exact_dob(p, dob)
    assert is_nil(result)
  end  

  test "assert match_dob_year when matches" do
    p = [{%P{patient_num: "123", date_of_birth: ~D[2017-01-01]}, []},
        {%P{patient_num: "1234", date_of_birth: ~D[2017-01-02]}, []},
        {%P{patient_num: "1235", date_of_birth: ~D[2017-01-03]}, []}]
    dob = ~D[2017-01-02]
    {p, _} = Determination.match_dob_year(p, dob)
    assert p.patient_num == "123"
  end  

  test "assert match_dob_year when not matches" do
    p = [{%P{patient_num: "123", date_of_birth: ~D[2017-01-01]}, []},
        {%P{patient_num: "1234", date_of_birth: ~D[2017-01-02]}, []},
        {%P{patient_num: "1235", date_of_birth: ~D[2017-01-03]}, []}]
    dob = ~D[2018-01-04]
    result = Determination.match_dob_year(p, dob)
    assert is_nil(result)
  end

  test "assert check dob_determination whet it matches a patient" do
    result = %DR{
      patients: [{%P{patient_num: "123", date_of_birth: ~D[2017-01-02]}, 
        [%PEL{start_date: ~D[2016-01-01], end_date: ~D[2018-01-01], group_id: 1},
        %PEL{start_date: ~D[2016-01-01], end_date: ~D[2016-01-02], group_id: 1}]}],
      submitted_rx_date: ~D[2017-01-01],
      submitted_group: {%G{id: 1,dob_determination: 0}, []},
      submitted_dob: ~D[2017-01-02]}
      |> Determination.check_dob_determination
    {p,_} = result.matched_patient
    assert result.match  && p.patient_num == "123" && result.reject_code == ""
  end

  test "assert check dob_determination whet it does not match a patient" do
    result = %DR{
      patients: [{%P{patient_num: "123", date_of_birth: ~D[2017-01-02]}, 
        [%PEL{start_date: ~D[2016-01-01], end_date: ~D[2018-01-01], group_id: 1},
        %PEL{start_date: ~D[2016-01-01], end_date: ~D[2016-01-02], group_id: 1}]}],
      submitted_rx_date: ~D[2017-01-01],
      submitted_group: {%G{id: 1,dob_determination: 0}, []},
      submitted_dob: ~D[2018-01-02]}
      |> Determination.check_dob_determination
    assert !result.match  && result.reject_code == "N1"
  end

  test "assert match_first_name when matches" do
    p = [{%P{patient_num: "123", first_name: "Erick"}, []},
        {%P{patient_num: "1234", first_name: "Jean"}, []},
        {%P{patient_num: "12345", first_name: "Ezequiel"}, []}]
    first_name = "Erick"
    {p, _} = Determination.match_first_name(p, first_name)
    assert p.patient_num == "123"
  end  

  test "assert match_first_name when not matches" do
    p = [{%P{first_name: "Erick"}, []},
        {%P{first_name: "Jean"}, []},
        {%P{first_name: "Ezequiel"}, []}]
    first_name = "Nick"
    result = Determination.match_first_name(p, first_name)
    assert is_nil(result)
  end

  test "assert check_personcode_determination when it matches" do
      result = %DR{
        patients: [{%P{patient_num: "123", first_name: "Erick"}, 
            [%PEL{start_date: ~D[2016-01-01], end_date: ~D[2018-01-01], group_id: 1},
            %PEL{start_date: ~D[2016-01-01], end_date: ~D[2016-01-02], group_id: 1}]}
            ],
        submitted_rx_date: ~D[2017-01-01],
        submitted_group: {%G{id: 1, personcode_determination: "F"},[]}, 
        submitted_first_name: "Erick"}
      |> Determination.check_personcode_determination
    {p,_} = result.matched_patient
    assert result.match  && p.patient_num == "123" && result.reject_code == ""
  end

  test "assert check_personcode_determination when it does not matches" do
      result = %DR{
        patients: [{%P{patient_num: "123", first_name: "Erick"}, 
            [%PEL{start_date: ~D[2016-01-01], end_date: ~D[2018-01-01], group_id: 1},
            %PEL{start_date: ~D[2016-01-01], end_date: ~D[2016-01-02], group_id: 1}]}
            ],
        submitted_rx_date: ~D[2017-01-01],
        submitted_group: {%G{id: 1, personcode_determination: "F"},[]}, 
        submitted_first_name: "Erick not match"}
      |> Determination.check_personcode_determination
    assert !result.match  && result.reject_code == "N1"
  end

  test "assert check_personcode_determination when is an uknow personcode_determination" do
      result = %DR{submitted_group: {%G{id: 1, personcode_determination: "Z"},[]}}
      |> Determination.check_personcode_determination
    assert !result.match  && result.reject_code == "85"
  end

  test "assert get_person_01 return the matched person" do
      result = %DR{patients: [{%P{patient_num: "123", person_code: "02"}, []},
            {%P{patient_num: "1234", person_code: "01"}, []}]}
      |> Determination.get_person_01
      {p,_} = result.matched_patient
    assert p.patient_num == "1234" 
  end

  test "assert get_person_01 return reject code 65" do
      result = %DR{patients: [{%P{patient_num: "123", person_code: "02"}, []},
            {%P{patient_num: "1234", person_code: "03"}, []}]}
      |> Determination.get_person_01
      
    assert !result.match  && result.reject_code == "65"
  end

  test "assert to get the first patient's first eligibility line as the submitted group" do
      result = [{%P{}, [%PEL{group_id: 5}, %PEL{group_id: 1}]},
            {%P{}, [%PEL{group_id: 2}, %PEL{group_id: 3}]}]
      |> Determination.get_group_from_patient

    assert result == 5  
  end
end
