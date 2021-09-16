defmodule GenReport do
  alias GenReport.Parser

  @report_months %{
    1 => "janeiro",
    2 => "fevereiro",
    3 => "março",
    4 => "abril",
    5 => "maio",
    6 => "junho",
    7 => "julho",
    8 => "agosto",
    9 => "setembro",
    10 => "outubro",
    11 => "novembro",
    12 => "dezembro"
  }

  def build(filename) do
    parsed_items = Parser.parse_file(filename)
    report = gen_acc(parsed_items)

    Enum.reduce(parsed_items, report, &sum_values/2)
  end

  def build_multiple(filenames) when is_list(filenames) do
    result =
      filenames
      |> Task.async_stream(&build/1)
      |> Enum.reduce(fn {:ok, result}, {:ok, report} -> sum_reports(result, report) end)

    {:ok, result}
  end

  def build_multiple() do
    {:error, "argumento precisa ser uma lista"}
  end

  def build() do
    {:error, "Insira o nome de um arquivo"}
  end

  defp sum_values(
         [name, hours, _day, month, year],
         %{all_hours: all_hours, hours_per_month: hours_per_month, hours_per_year: hours_per_year}
       ) do
    all_hours = Map.put(all_hours, name, all_hours[name] + hours)

    old_month_value = get_in(hours_per_month, [name, @report_months[month]])

    hours_per_month =
      put_in(hours_per_month, [name, @report_months[month]], old_month_value + hours)

    old_year_value = get_in(hours_per_year, [name, year])

    hours_per_year = put_in(hours_per_year, [name, year], old_year_value + hours)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp gen_acc(entries) do
    names =
      entries
      |> Enum.map(&hd(&1))
      |> Enum.uniq()

    all_hours = Enum.into(names, %{}, &{&1, 0})

    hours_per_month =
      Enum.into(names, %{}, fn x ->
        {x, Enum.into(Map.values(@report_months), %{}, &{&1, 0})}
      end)

    hours_per_year =
      Enum.into(names, %{}, fn x ->
        {x, Enum.into(2016..2020, %{}, &{&1, 0})}
      end)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp build_report(all_hours, hours_per_month, hours_per_year) do
    %{
      all_hours: all_hours,
      hours_per_month: hours_per_month,
      hours_per_year: hours_per_year
    }
  end

  defp sum_reports(
         %{
           all_hours: all_hours1,
           hours_per_month: hours_per_month1,
           hours_per_year: hours_per_year1
         },
         %{
           all_hours: all_hours2,
           hours_per_month: hours_per_month2,
           hours_per_year: hours_per_year2
         }
       ) do
    new_all_hours = Map.merge(all_hours1, all_hours2, fn _key, val1, val2 -> val1 + val2 end)

    new_hours_per_month = deep_merge(hours_per_month1, hours_per_month2)

    new_hours_per_year = deep_merge(hours_per_year1, hours_per_year2)

    {:ok, build_report(new_all_hours, new_hours_per_month, new_hours_per_year)}
  end

  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  defp deep_resolve(_key, left, right) when is_map(left) and is_map(right) do
    deep_merge(left, right)
  end

  defp deep_resolve(_key, left, right) when is_integer(left) and is_integer(right) do
    left + right
  end
end
