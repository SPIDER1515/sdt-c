defmodule NA.Adj.PatientEligibility do

  defp result_elig(is_elig, head) do
    {is_elig, head}
  end

  defp verify_elig([], _) do
    result_elig(:false, [])
  end

  defp verify_elig([head | tail], date_of_service) do
    if Date.compare(head.start_date, date_of_service) != :gt && (is_nil(head.end_date) || Date.compare(date_of_service, head.end_date) != :lt) do
      result_elig(:true, head.item_id)
    else
      verify_elig(tail, date_of_service)
    end
  end

  def verify_patient_eligibility(patient_num, date_of_service) do
    subscriber = NA.DB.Repo.Patient.get_by_patient_num(patient_num) 
    {_, elig, _} = subscriber
    {is_elig, elig_line} = verify_elig(elig, date_of_service)
    {is_elig, elig_line, subscriber}
  end
end
