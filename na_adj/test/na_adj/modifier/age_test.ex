defmodule NA.ADJ.Test.Modifier.Age do
  use ExUnit.Case, async: true
  
  alias NA.ADJ.Modifiers.Age

  test "Match female age list" do
    age = %{mony_type: "Y", female_min_age: 0, female_max_age: 25, male_min_age: 0, male_max_age: 25}
    age2 = %{mony_type: "M", female_min_age: 0, female_max_age: 25, male_min_age: 0, male_max_age: 25}
    age3 = %{mony_type: "O", female_min_age: 0, female_max_age: 18, male_min_age: 0, male_max_age: 25}
    age4 = %{mony_type: "M", female_min_age: 0, female_max_age: 25, male_min_age: 0, male_max_age: 25}
    age5 = %{mony_type: "O", female_min_age: 0, female_max_age: 25, male_min_age: 0, male_max_age: 25}
    age_list = [age, age2, age3, age4, age5]

    patient = %{gender: "F", age: 21}
    drug = %{mony_type: "O"}

    actual_result = Age.match_age_list(age_list, patient.gender, patient.age, drug)

    assert actual_result == age5
  end

  test "Match male age list" do
    age = %{mony_type: "Y", female_min_age: 0, female_max_age: 25, male_min_age: 0, male_max_age: 25}
    age2 = %{mony_type: "M", female_min_age: 0, female_max_age: 25, male_min_age: 0, male_max_age: 18}
    age3 = %{mony_type: "O", female_min_age: 0, female_max_age: 18, male_min_age: 0, male_max_age: 25}
    age4 = %{mony_type: "M", female_min_age: 0, female_max_age: 25, male_min_age: 0, male_max_age: 25}
    age5 = %{mony_type: "O", female_min_age: 0, female_max_age: 25, male_min_age: 0, male_max_age: 25}
    age_list = [age, age2, age3, age4, age5]

    patient = %{gender: "M", age: 21}
    drug = %{mony_type: "M"}

    actual_result = Age.match_age_list(age_list, patient.gender, patient.age, drug)

    assert actual_result == age4
  end

end
