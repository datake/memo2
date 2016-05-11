require 'csv'

edge_weight=[1,1.5,2,2.5]
source_target_node_num_type=[1,2,3]

source_target_node_num_type.each{|source_target_kind|
  edge_weight.each{|language|
    input="#{language}-#{source_target_kind}"

    input_filename="dummy_transgraph/"+input+".csv"
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
