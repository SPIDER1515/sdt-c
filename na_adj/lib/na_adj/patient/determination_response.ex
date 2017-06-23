defmodule NA.ADJ.Patient.DeterminationResponse do
  
  alias NA.DB.Schema.Patient_eligibility_list, as: PEL
  alias NA.DB.Schema.Patient, as: P
  alias NA.DB.Schema.Groups, as: G
  
  defstruct submitted_group: nil, submitted_rx_date: nil, submitted_dob: nil, submitted_first_name: nil,
  patients: nil, patient_num: nil, matched_patient: nil, group_num: nil, 
  submitted_group: nil, active_eligibility: nil, match: false, reject_code: "", additional_rejects: []

  @typedoc """
  A structure to define the response from the `NA.ADJ.Patient.PatientDetermination` module.
  """
  @type t :: %__MODULE__{
    submitted_group: {G.t, []},
    submitted_rx_date: Calendar.date,
    submitted_dob: Calendar.date,
    submitted_first_name: String.t,
    patients: [] | nil,
    matched_patient: {P.t, [PEL.t]},
    patient_num: String.t,
    group_num: String.t,
    active_eligibility: %{} | nil,
    match: bool,
    reject_code: String.t,
    additional_rejects: [String.t]
  }
  
  @spec new_from_patient(P) :: t
  def new_from_patient(patients) do
    %__MODULE__{patients: patients}
  end
end