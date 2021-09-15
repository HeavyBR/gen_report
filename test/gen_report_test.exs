defmodule GenReportTest do
  use ExUnit.Case

  @file_name "gen_report.csv"

  describe "parse_file/1" do
    test "Should parse all lines correctly" do
      parsed_lines =
        @file_name
        |> GenReport.Parser.parse_file()
        |> Enum.map(& &1)

      assert Enum.any?(parsed_lines, &(&1 == ["Daniele", 1, 19, 6, 2018])) == true
    end
  end
end
