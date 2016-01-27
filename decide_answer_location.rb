require 'csv'
require 'pp'
require 'logger'
require 'set'
require 'unf'

def main
  # decide_answer_locations
  decide_answer_location_lmh
  # decide_answer_location_same_num
end
class Array
  # 要素の平均を算出する
  def avg
    inject(0.0){|r,i| r+=i }/size
  end
  # 要素の分散を算出する
  def variance
    a = avg
    inject(0.0){|r,i| r+=(i-a)**2 }/size
  end
  # 標準偏差を算出する
  def standard_deviation
    Math.sqrt(variance)
  end
end
def split_comma_to_array (text)
  # text=text.gsub(/"/, '')
  lang_arr=text.split(",")
  return lang_arr
end
class Transgraph
  def initialize(input_filename)
    @pivot = {}
    @lang_a_b = {}
    @lang_b_a = {}
    @lang_a_p = {}
    @lang_b_p = {}
    @lang_p_a = {}
    @lang_p_b = {}
    @node_a = Set.new
    @node_b = Set.new
    CSV.foreach(input_filename) do |row|
      if row.size==3
        array_of_a = split_comma_to_array(row[1])
        # if row[2]
        array_of_b  = split_comma_to_array(row[2])
        # pp array_of_b
        @pivot[row[0]]=[array_of_a,array_of_b] #{"pivot"=>[[a1,a2,a3,..], [b1,b2,b3,..]]}

        @lang_p_a[row[0]] = array_of_a
        @lang_p_b[row[0]] = array_of_b
        array_of_a.each{|a|
          array_of_b.each{|b|
            @lang_a_b[a]=array_of_b #{"a1"=>[b1,b2,b3,..]}とか{"a2"=>[b1,b2,b3,..]}
            @lang_b_a[b]=array_of_a #{"b1"=>"a1,a2,a3,..]"}
            #aやbからみたとき、複数のpivotが対応することがある
            if @lang_a_p.has_key?(a)
              @lang_a_p[a] << row[0] #{"a1"=>Set[pivot1,pivot2,..]}
              # pp @lang_a_p[a]
            else
              @lang_a_p[a]=Set[row[0]] #{"a1"=>Set[pivot]}
            end
            if @lang_b_p.has_key?(b)
              @lang_b_p[b] << row[0] #{"b1"=>Set[pivot1,pivot2,..]}
              # pp @lang_b_p[b]
            else
              @lang_b_p[b]=Set[row[0]] #{"b1"=>"Set[pivot]}
              # pp @lang_b_p[b][0]

            end
          }
        }
        array_of_a.each{|a|
          @node_a<<a.to_s
        }
        array_of_b.each{|b|
          @node_b<<b.to_s
        }
      end
    end
  end
  attr_accessor :pivot
  attr_accessor :lang_a_b
  attr_accessor :lang_b_a
  attr_accessor :lang_a_p
  attr_accessor :lang_b_p
  attr_accessor :lang_p_a
  attr_accessor :lang_p_b
  attr_accessor :node_a
  attr_accessor :node_b
end

class Answer
  def initialize(answer_filename)
    @answer = {}
    # @answer_head_trans = {}
    @answer_head_trans = Hash.new {|h,k| h[k]=[]}
    CSV.foreach(answer_filename) do |row|
      @answer[row[0]]=row[1..-1]
      if row[0 .. -1].size>1
        row[1..-1].each{|trans|
          if answer_head_trans.has_key?(trans)
            answer_head_trans[trans] << row[0]
            #まだ登録されていないkeyならvalueに追加
          else
            answer_head_trans[trans] << row[0]
          end
        }
      end
    end
  end
  attr_accessor :answer
  attr_accessor :answer_head_trans
end

def decide_answer_location_lmh
  languages = ["1-0","1-5","2","2-2","2-5","2-8"]
  languages.each{|language|
    # output_file_low="answer/type-low/"+language+".csv"
    # output_file_middle="answer/type-middle/"+language+".csv"
    # output_file_high="answer/type-high/"+language+".csv"
    #
    output_file_u20="answer/u20/"+language+".csv"
    output_file_u40="answer/u40/"+language+".csv"
    output_file_u50="answer/u50/"+language+".csv"
    output_file_u60="answer/u60/"+language+".csv"
    output_file_u70="answer/u70/"+language+".csv"
    output_file_u80="answer/u80/"+language+".csv"
    output_file_u90="answer/u90/"+language+".csv"
    output_file_u100="answer/u100/"+language+".csv"

    # File.open(output_file_low, "a") do |io_out_low|
    #   File.open(output_file_middle, "a") do |io_out_middle|
    #     File.open(output_file_high, "a") do |io_out_high|
    File.open(output_file_u20, "a") do |io_out_u20|
      File.open(output_file_u50, "a") do |io_out_u50|
        File.open(output_file_u70, "a") do |io_out_u70|
          File.open(output_file_u90, "a") do |io_out_u90|
            File.open(output_file_u40, "a") do |io_out_u40|
              File.open(output_file_u60, "a") do |io_out_u60|
                File.open(output_file_u80, "a") do |io_out_u80|
                  File.open(output_file_u100, "a") do |io_out_u100|
                    # pivot_connected_fixed=2 #ピボット共有率を計測する際の分母(繋がっているノード数)を指定
                    min=0

                    max=999
                    input_filename="partition/"+language+"/"

                    all_trans_sr_standardized=Array.new
                    min.upto(max) do |transgraph_itr|
                      pp input_filename+"#{transgraph_itr}.csv"
                      transgraph = Transgraph.new(input_filename+"#{transgraph_itr}.csv")

                      pivot_connected=Set.new
                      pivot_share=Set.new
                      transgraph.node_a.each{|node_a|
                        transgraph.node_b.each{|node_b|
                          pivot_connected=transgraph.lang_a_p[node_a] + transgraph.lang_b_p[node_b]#setの和部分
                          pivot_share=transgraph.lang_a_p[node_a] & transgraph.lang_b_p[node_b]#setの共通部分
                          if pivot_connected.size==0 #繋がっていないものがある場合は母集団としカウントしない
                            # print("とばす")
                          else
                            if pivot_connected.size > 1
                              share_ratio =pivot_share.size.fdiv(pivot_connected.size)
                              if share_ratio < 0.2
                                io_out_u20.puts("#{node_a},#{node_b}")
                              elsif share_ratio < 0.4
                                io_out_u40.puts("#{node_a},#{node_b}")
                              elsif share_ratio < 0.5
                                io_out_u50.puts("#{node_a},#{node_b}")
                              elsif share_ratio < 0.6
                                io_out_u60.puts("#{node_a},#{node_b}")
                              elsif share_ratio < 0.7
                                io_out_u70.puts("#{node_a},#{node_b}")
                              elsif share_ratio < 0.8
                                io_out_u80.puts("#{node_a},#{node_b}")
                              elsif share_ratio < 0.9
                                io_out_u90.puts("#{node_a},#{node_b}")
                              else
                                io_out_u100.puts("#{node_a},#{node_b}")
                              end
                            end
                          end
                        }
                      }

                      #
                      #
                      # if transgraph.node_a.size > transgraph.node_b.size
                      #   transgraph.node_b.each_with_index {|node_b, idx|
                      #     # io_out.puts("#{transgraph_itr}-a-#{idx},#{transgraph_itr}-b-#{idx}")
                      #   }
                      # else
                      #   transgraph.node_a.each_with_index {|node_a, idx|
                      #     # io_out.puts("#{transgraph_itr}-a-#{idx},#{transgraph_itr}-b-#{idx}")
                      #   }
                      # end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

  }
end
#つながっているものの中から選択する
def decide_answer_location_same_num
  languages = ["1-0","1-5","2","2-2"]
  languages.each{|language|
    output_filename="answer/same_num/"+language+".csv"

    File.open(output_filename, "a") do |io_out|

      min=0

      max=999
      input_filename="partition/"+language+"/"

      all_trans_sr_standardized=Array.new
      min.upto(max) do |transgraph_itr|
        pp input_filename+"#{transgraph_itr}.csv"
        transgraph = Transgraph.new(input_filename+"#{transgraph_itr}.csv")

        # transgraph.node_a.each{|node_a|
        #   transgraph.node_b.each{|node_b|
        #
        #
        #   }
        # }
        # is_already_reachable_answer={}
        # # if language=="Ind_Mnk_Zsm"
        # if transgraph.lang_a_b.has_key?(answer_key)#同じ日本語の見出し語があるか
        #   if transgraph.lang_a_b[answer_key].include?(answer_value)#同じドイツ語の単語があるか
        #     pp "#{answer_key} #{answer_value} exists"
        #     kvstring+="#{answer_key}:#{answer_value},"
        #     pivot_connected=transgraph.lang_a_p[answer_key] + transgraph.lang_b_p[answer_value]#setの和部分
        #     pivot_share=transgraph.lang_a_p[answer_key] & transgraph.lang_b_p[answer_value]#setの共通部分
        #
        #     if pivot_connected.size > 1 #答えペアのピボット共有率の分母が1の場合はランダム要素が多いので弾く
        #       # if pivot_connected.size ==pivot_connected_fixed
        #       #答えがもともと繋がっていない場合は省く
        #       if pivot_share.size !=0
        #         pivot_connected_num_answer.push(pivot_connected.size)#answer_valueとanswer_keyと接続しているpivot
        #         pivot_share_num_answer.push(pivot_share.size)
        #         share_ratio_answer.push(pivot_share_num_answer[-1].fdiv(pivot_connected_num_answer[-1])) #pivotの共有率
        #         pp "こたえあり"
        #       end
        #     end
        #     # else
        #   end
        # end


        if transgraph.node_a.size > transgraph.node_b.size
          transgraph.node_b.each_with_index {|node_b, idx|

            io_out.puts("#{transgraph_itr}-a-#{idx},#{transgraph_itr}-b-#{idx}")
          }
        else
          transgraph.node_a.each_with_index {|node_a, idx|
            io_out.puts("#{transgraph_itr}-a-#{idx},#{transgraph_itr}-b-#{idx}")
          }
        end
      end
    end
  }

end

main
