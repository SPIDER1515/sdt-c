defmodule NA.Adj.HistoryLookup do
  import Ecto.Query

  alias NA.DB.Schema.Claim
  alias NA.DB.Repo

  def get_by_patient_id(patient_id) do
    query =
      from d in Claim,
      where: d.patient_id == ^patient_id,
      order_by: d.updated_at

    case Repo.all(query) do
      [] -> nil
      [_|_] = claims -> claims
    end
  end

end


