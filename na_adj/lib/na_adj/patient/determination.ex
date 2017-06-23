defmodule NA.ADJ.Patient.Determination do
  
  alias NA.DB.Schema.Patient_eligibility_list, as: PEL
  alias NA.DB.Schema.Patient, as: P
  alias NA.DB.Schema.Groups, as: G
  alias NA.ADJ.Patient.DeterminationResponse, as: DR
  alias NA.DB.Repo.Groups, as: GroupRepo

  def match_patient(%DR{} = dr) do
    with dr <- set_submitted_group(dr),
      dr <- check_member_determination(dr) do 
        dr
    end
  end

  def set_submitted_group(%DR{submitted_group: nil, patients: pats} = dr) do
    group = 
      get_group_from_patient(pats)
      |> GroupRepo.get_by_id
    %DR{dr | submitted_group: group}
  end

  def set_submitted_group(%DR{} = dr), do: dr
  
  def get_group_from_patient([{_,[%PEL{group_id: group_id}|_]}|_]), do: group_id

  def check_member_determination(%DR{submitted_group: {%G{member_determination: md } = g, _}} = dt) 
    when md == "E" do
    
    dt = get_person_01(dt)
    case dt.match do
      true ->
        dt = find_active_eligibility_line(dt)
        case dt.match do
          true -> check_coverage_type(dt)
          false -> reject(dt,"99")
        end
      false -> dt
    end
  end

  def check_member_determination(%DR{submitted_group: {%G{member_determination: md } = g, _}} = dt) 
    when md == "P" do
    check_personcode_determination(dt)
  end

  def check_member_determination(dt) do
    reject(dt,"85")
  end

  def check_coverage_type(%DR{active_eligibility: %PEL{coverage_type: ct} = elig, matched_patient: p} = dt) 
    when ct == "IND" do 
    dt = %DR{dt | patients: [p]}
    case is_nil(dt.submitted_dob) do
      true -> check_first_name(dt)
      false -> check_dob_determination(dt)
    end
  end

  def check_coverage_type(%DR{active_eligibility: %PEL{coverage_type: ct} = elig} = dt) when ct == "FAM" do 
    case is_nil(dt.submitted_dob) do
      true -> check_first_name(dt)
      false -> check_dob_determination(dt)
    end
  end

  def get_person_01(%DR{patients: patients} = dt) do
    matched = Enum.filter(patients,fn {p,_} -> p.person_code == "01" end)
    case length(matched) == 0 do
      true -> reject(dt, "65")
      false -> %DR{dt | matched_patient: List.first(matched)}
    end
  end

  def check_personcode_determination(%DR{submitted_group: {%G{personcode_determination: pc } = g, _}} = dt) 
    when pc == "F" or pc == "L" do
    case is_nil(dt.submitted_dob) do
      true -> check_first_name(dt)
      false -> check_dob_determination(dt)
    end
  end

  def check_personcode_determination(dt) do
   reject(dt, "85")
  end
  
  def check_first_name(%DR{submitted_first_name: submitted_name, patients: ps} = dt) do
    case is_nil(submitted_name) do
      true -> reject(dt, "N1")
      false -> 
        p = match_first_name(ps, submitted_name)
        case is_nil(p) do
          true -> reject(dt, "N1")
          false ->
            dt = %DR{dt | matched_patient: p}
            find_active_eligibility_line(dt)
        end
    end
  end

  def match_first_name([{%P{first_name: name}, _}= h|t], submitted_name) do
    case name == submitted_name do
      true -> h
      false -> match_first_name(t, submitted_name)
    end
  end
 
  def match_first_name([], submitted_name) do
    nil
  end

  def check_dob_determination(%DR{submitted_group: {g, _}, patients: p, submitted_dob: dob} = dt) do
    patient = case g.dob_determination do
      0 -> match_exact_dob(p, dob)
      1 -> match_dob_year(p, dob)
      _ -> reject(dt, "N1")
    end

    case is_nil(patient) do
      true -> reject(dt, "N1")
      false -> find_active_eligibility_line(%DR{dt | matched_patient: patient})
    end
  end

  def match_exact_dob([{%P{date_of_birth: dob}, _}= h|t], submitted_dob) do
    case dob == submitted_dob do
      true -> h
      false -> match_exact_dob(t, submitted_dob)
    end
  end
 
  def match_exact_dob([], _submitted_dob) do
    nil
  end

  def match_dob_year([{%P{date_of_birth: dob}, _}= h|t], submitted_dob) do
    case dob.year == submitted_dob.year do
      true -> h
      false -> match_exact_dob(t, submitted_dob)
    end
  end

  def match_dob_year([], _submitted_dob) do
    nil
  end
  
  def find_active_eligibility_line(%DR{matched_patient: {p, eligs}, submitted_rx_date: rx_date, submitted_group: {g, _}} = dt) do
    active_elig_lines = get_active_eligibility_line(eligs, rx_date)
    case length(active_elig_lines) do
      1 -> match_group(active_elig_lines, dt)
      0 -> reject(dt, "600")
      _ -> reject(dt, "99")
    end
  end

  def find_active_eligibility_line(%DR{matched_patient: {p, eligs}, submitted_rx_date: rx_date, submitted_group: nil} = dt) do
    active_elig_lines = get_active_eligibility_line(eligs, rx_date)
    case length(active_elig_lines) do
      1 -> %DR{dt | active_eligibility: List.first(active_elig_lines)}
      0 -> reject(dt, "600")
      _ -> reject(dt, "99")
    end
  end
  
  def match_group([elig], %DR{submitted_group: {submitted_group, _}} = dt) do
    case elig.group_id == submitted_group.id do
      true -> dt = %DR{dt | match: true}
              %DR{dt | active_eligibility: elig}
      false -> reject(dt,"51")
    end
  end

  def get_active_eligibility_line(eligs, rx_date) do
    Enum.filter(eligs,fn e -> NA.Shared.Date.date_is_active(rx_date, e.start_date, e.end_date) end)
  end

  def reject(dt, code) do
    dt = %DR{dt | reject_code: code}
    %DR{dt | match: false}
  end
end