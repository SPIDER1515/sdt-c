defmodule NA.ADJ.Modifiers.Age do

  def get_age_list(id) do
    NA.DB.Repo.Modifiers.get_age_by_id(id)
    |> verify_age
  end

  defp verify_age(nil) do
    {:error, ""}
  end

  defp verify_age(age) do
    age
  end

  def match_age_list([], _patient, _drug) do
    {:error, "NO MATCH"}
  end

  def match_age_list([h | t], gender, age, drug) do
      with true <- h.mony_type == drug.mony_type,
            %{} = age_list <- match_age(h, gender, age)
      do 
        age_list
      else
        _ -> match_age_list(t, gender, age, drug)
      end
  end

  defp match_age(h, "F", age) do
    case h.female_min_age <= age && h.female_max_age >= age do
      true -> h
      _ -> nil
  end
end

  defp match_age(h, "M", age) do
    case h.male_min_age <= age && h.male_max_age >= age do
      true -> h
      _ -> nil
    end
  end

end
