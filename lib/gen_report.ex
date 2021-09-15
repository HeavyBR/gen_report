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

  def sum_values(
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

  def build() do
    {:error, "Insira o nome de um arquivo"}
  end

  def gen_acc(entries) do
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

  def build_report(all_hours, hours_per_month, hours_per_year) do
    %{
      all_hours: all_hours,
      hours_per_month: hours_per_month,
      hours_per_year: hours_per_year
    }
  end
end
