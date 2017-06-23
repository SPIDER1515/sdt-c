defmodule NA.ADJ.Patient.Patient do
  alias NA.ADJ.Patient.DeterminationResponse, as: DR
  alias NA.ADJ.Patient.Groups, as: G

  def get_patients(dt) do
    patients = NA.DB.Repo.Patient.get_by_patient_num(dt.patient_num)
    %DR{dt | patients: patients}
  end

  def get_match_patient(patient_num, group_num) do
    %DR{patient_num: patient_num, group_num: group_num}
    |> get_patients
    |> G.get_group
    |> G.validate_groups
  end
end