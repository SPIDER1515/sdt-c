defmodule NA.ADJ.Patient.Groups do
  alias NA.ADJ.Patient.DeterminationResponse, as: DR

  def get_group(dt) do
    group = NA.DB.Repo.Groups.get_by_group_num(dt.group_num)
    %DR{dt | submitted_group: group}
  end
  # if the patient count = 1 then send it back
  def validate_groups(%DR{patients: p} = dt) when length(p) <= 1, do: dt

  def validate_groups(%DR{patients: p, submitted_group: sg} = dt) when length(p) > 1 and is_nil(sg) == false, do: dt

  def validate_groups(%DR{patients: p, submitted_group: nil} = dt) when length(p) > 1  do
    group_id = get_first_group_id(p)
    case is_nil(group_id) do
      true ->  %DR{dt | reject_code: "N1"}
      false ->  case patients_same_group?(p, group_id) do
                  true -> dt
                  false -> %DR{dt | reject_code: "06"}
                end 
    end
  end

  def patients_same_group?(patients, group_id) do
    !Enum.any?(patients, fn {p, e} -> mismatch_group?(e, group_id) end)
  end

  def get_first_group_id([{p,e}|t]) do
    case is_nil(e) do
      true -> get_first_group_id(t)
      false -> List.first(e).group_id
    end
  end

  def get_first_group_id([]) do
    nil
  end

  def mismatch_group?(nil, group_id) do
    false
  end

  def mismatch_group?(elig_lines, group_id) do
    Enum.any?(elig_lines, fn e -> e.group_id != group_id end)
  end
end