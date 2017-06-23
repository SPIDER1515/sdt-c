defmodule NA.ADJ.Prescriber.Prescriber do
  alias NA.DB.Repo.Prescriber

  def get_by_id(id) do
    Prescriber.get_by_id(id)
  end

  def get_by_dea(dea) do
    Prescriber.get_by_dea(dea)
  end

  def get_by_npi(npi) do
    Prescriber.get_by_npi(npi)
  end
  
  def is_npi?(npi) do
    Regex.match?(~r/(?<!\d)\d{10}(?!\d)/, npi)
  end

  def is_dea?(dea) do
    Regex.match?(~r/[a-zA-Z]{2}\d{7}/, dea)
  end

  def is_npi_checksum?(npi) do
    {i_sum, check_num} =
      String.graphemes(npi)
      |> double_odd_indexed_and_sum_all({0,0})
      |> add_prefix_and_check_num
    next_ten = get_next_ten(i_sum)
    calc_check_num = next_ten - i_sum 
    
    calc_check_num == check_num
  end

  defp double_odd_indexed_and_sum_all([], resp), do: resp
  defp double_odd_indexed_and_sum_all([h|t], {sum, check}) do
    l = length(t)
    pd = 
      String.to_integer(h)
      |> process_digit(l, sum)
    case l do
      1 -> {pd, t}
      _ -> double_odd_indexed_and_sum_all(t, {pd, check})
    end
  end

  defp add_prefix_and_check_num({i_sum, [check_num]}) do
    i_sum = i_sum + 24
    check_num = String.to_integer(check_num)
 
    {i_sum, check_num}
  end

  defp sum_acc(digit, sum) do
    digit + sum
  end

  defp get_next_ten(sum) do
    acc = sum + 1
    case rem(acc, 10) do
      0 -> acc
      _ -> get_next_ten(acc)
    end
  end

  defp process_digit(val, l, acc) do
    double_odd_indexed(val, l)
    |> Integer.digits
    |> sum_list
    |> sum_acc(acc)
  end

  defp double_odd_indexed(val, l) do
     case rem(l, 2) do
      0 -> val
      _ -> val * 2 
    end
  end
  
  defp sum_list(list), do: do_sum_list(list,0)
  
  defp do_sum_list(l,i_acc), do: Enum.reduce(l, i_acc, fn(x, accum) -> x + accum end)

end
