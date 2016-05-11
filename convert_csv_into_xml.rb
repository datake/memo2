require 'csv'

# puts "変換するcsvファイルを拡張子なしで指定(例 joined/en-ja-de)"
# input=$stdin.gets.chomp
# languages = ["1-2","1-5","1-8","2-0"]
# languages = ["0-8","1-0","2-2","2-5","2-8","3-0"]

# languages=["1-0","1-5"]#,"2-0","2-5"]
languages=["2-0","2-5"]
source_target_kinds=[1,2,3]

source_target_kinds.each{|source_target_kind|


languages.each{|language|
  input="simulation_data-#{language}-#{source_target_kind}"

  input_filename="input/"+input+".csv"
  output_filename="xml/#{input}.xml"

  File.open(output_filename, "w") do |out|
    out.puts "<?xml version='1.0' ?>"
    out.puts "<DocumentElement>"
    CSV.foreach(input_filename) do |row|
      out.puts "<zuk_fixed>"
      out.puts  "<Zh>#{row[0]}</Zh>"
      out.puts  "<Pn>-</Pn>"
      out.puts  "<Ug>#{row[1]}</Ug>"
      out.puts  "<Kz>#{row[2]}</Kz>"
      out.puts  "</zuk_fixed>"
    end
    out.puts "</DocumentElement>"
  end

}
}
