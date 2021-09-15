defmodule GenReport.Parser do
  def parse_file(filename) do
    "reports/#{filename}"
    |> File.stream!()
    |> Stream.map(&parse_line/1)
  end

  defp parse_line(line) do
    line
    |> String.trim()
    |> String.split(",")
    |> Enum.map(fn item ->
      case Integer.parse(item) do
        {int, _} -> int
        :error -> item
      end
    end)
  end
end
