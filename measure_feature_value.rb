require 'csv'
require 'pp'
require 'logger'
require 'set'
require 'unf'

def main
  measure_feature_value_weighted_average_selection_probability

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
def levenshtein_distance(s, t)
  m = s.length
  n = t.length
  return m if n == 0
  return n if m == 0
  d = Array.new(m+1) {Array.new(n+1)}

  (0..m).each {|i| d[i][0] = i}
  (0..n).each {|j| d[0][j] = j}
  (1..n).each do |j|
    (1..m).each do |i|
      d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
        d[i-1][j-1]       # no operation required
      else
        [ d[i-1][j]+1,    # deletion
        d[i][j-1]+1,    # insertion
        d[i-1][j-1]+1,  # substitution
      ].min
    end
  end
end
d[m][n]
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
    @answer_head_trans = Hash.new {|h,k| h[k]=[]}
    CSV.foreach(answer_filename) do |row|
      if row.size>=2
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
  end
  attr_accessor :answer
  attr_accessor :answer_head_trans
end
class Result
  def initialize(result_filename)
    @result = {}
    @result_head_trans = Hash.new {|h,k| h[k]=[]}
    @is_true=Hash.new { |h,k| h[k] = {} } #二重ハッシュ
    CSV.foreach(result_filename) do |row|
      if row.size>=2
        @result[row[0]]=row[1]
        @result_head_trans[row[1]]=row[0]
        @is_true[row[0]][row[1]]=[row[2]]
      end
    end
  end
  attr_accessor :result
  attr_accessor :result_head_trans
  attr_accessor :is_true

end


def split_comma_to_array (text)
  # text=text.gsub(/"/, '')
  lang_arr=text.split(",")
  return lang_arr
end



def measure_feature_value_weighted_average_selection_probability
  # languages = ["JaToEn_EnToDe","JaToDe_DeToEn","JaToEn_JaToDe","Ind_Mnk_Zsm2","Zh_Uy_Kz"]
  # languages = ["1-2"]
  # languages = ["1-0","1-5","2","2-2"]
  languages = ["1-0","1-5","2","2-2","2-5","2-8"]

  # edge_slope="2-0"
  # answer_types=["type0","type1"]
  # answer_types=["type-low","type-middle","type-high"]
  answer_types=["u20","u40","u50","u60","u70","u80","u90","u100"]

  t = Time.now
  strTime = t.strftime("%B-%d-%H-%M-%S")
  File.open("features_value/features_value_all_#{strTime}.csv", "w") do |io_all|
    File.open("features_value/share_ratio_all_#{strTime}.csv", "w") do |io_all_standardized_sr|
      languages.each{|language|
        answer_types.each{|answer_type|
          is_population_connected_only=1 #母集団の取り方
          # pivot_connected_fixed=2 #ピボット共有率を計測する際の分母(繋がっているノード数)を指定
          output_folder="features_value/"

          answer_filename="answer/#{answer_type}/#{language}.csv"
          input_filename="partition/#{language}/"
          max=999 #Indのときだけ0からはじめる
          min=0

          answer = Answer.new(answer_filename)
          # one_to_one = Result.new("1-1/csv/"+one_to_one_filename+".csv")

          all_trans_sr_standardized=Array.new
          File.open(output_folder+"features_#{language}_#{answer_type}.csv", "w") do |io|
            #重要
            pair_reachable=Array.new
            pair_standardized_share_ratio=Array.new
            all_sr_divide_reachable=Array.new
            all_sr=Array.new
            all_reachable_target=Array.new
            min.upto(max) do |transgraph_itr|
              transgraph = Transgraph.new(input_filename+"#{transgraph_itr}.csv")
              pivot_connected=Set.new
              pivot_share=Set.new
              raw_output={}

              pivot_connected_num=Array.new #答えのA-Bペアのどちらかと繋がっているpivotの数
              pivot_share_num=Array.new #答えのA-Bペアの両方と繋がっているpivotの数
              share_ratio=Array.new #pivotの共有率
              precision_arr=Array.new
              each_trans_sr_standardized=Array.new
              string_precision=""

              #適合率計算用
              is_true=0
              is_false=0
              is_not_included=0
              # 母集団データのピボット共有率の計測
              transgraph.node_a.each{|node_a|
                transgraph.node_b.each{|node_b|
                  pivot_connected=transgraph.lang_a_p[node_a] + transgraph.lang_b_p[node_b]#setの和部分
                  pivot_share=transgraph.lang_a_p[node_a] & transgraph.lang_b_p[node_b]#setの共通部分
                  if is_population_connected_only==1 && pivot_connected.size==0 #繋がっていないものがある場合は母集団としカウントしない
                    # print("とばす")
                  else
                    pivot_connected_num.push(pivot_connected.size)#answer_valueとanswer_keyと接続しているpivot
                    pivot_share_num.push(pivot_share.size)
                    share_ratio.push(pivot_share_num[-1].fdiv(pivot_connected_num[-1])) #pivotの共有率
                  end
                }
              }

              reachable_node_num_arr=Array.new #pivotの共有率

              pivot_connected_num_answer=Array.new #答えのA-Bペアのどちらかと繋がっているpivotの数
              pivot_share_num_answer=Array.new #答えのA-Bペアの両方と繋がっているpivotの数
              share_ratio_answer=Array.new #pivotの共有率
              has_answer=0
              kvstring=""
              reachable_node_num_answer=Array.new #pivotの共有率
              reachable_node_num_answer=0
              is_already_reachable_answer={}

              #答えのピボット共有率
              answer.answer.each{|answer_key, answer_values|
                if answer_values
                  answer_values.each{|answer_value|#全てのanswerのA-Bについて走査
                    # is_already_reachable_answer={}
                    if transgraph.lang_a_b.has_key?(answer_key)#同じ日本語の見出し語があるか
                      if transgraph.lang_a_b[answer_key].include?(answer_value)#同じドイツ語の単語があるか
                        # pp "#{answer_key} & #{answer_value} exists"
                        kvstring+="#{answer_key} and #{answer_value} exists"
                        pivot_connected=transgraph.lang_a_p[answer_key] + transgraph.lang_b_p[answer_value]#setの和部分
                        pivot_share=transgraph.lang_a_p[answer_key] & transgraph.lang_b_p[answer_value]#setの共通部分

                        #答えがもともと繋がっていない場合は省く
                        if pivot_share.size > 0 && share_ratio.size > 0
                          #こたえペアのピボット共有率計測
                          pivot_connected_num_answer.push(pivot_connected.size)#answer_valueとanswer_keyと接続しているpivot
                          pivot_share_num_answer.push(pivot_share.size)
                          sr_of_this_pair=pivot_share_num_answer[-1].fdiv(pivot_connected_num_answer[-1])

                          share_ratio_answer.push(sr_of_this_pair) #pivotの共有率
                          #reachable計測
                          reachable_node_num=0
                          is_already_reachable={}
                          transgraph.lang_a_p[answer_key].each{|reachable_pivot|
                            transgraph.lang_p_b[reachable_pivot].each{|reachable_target|
                              if is_already_reachable.has_key?(reachable_target) && is_already_reachable[reachable_target]==1
                                # pp "reachableすでに登録済み"
                              else
                                reachable_node_num+=1
                                is_already_reachable[reachable_target]=1
                              end
                            }
                          }
                          reachable_node_num_arr.push(reachable_node_num)
                        end
                      end
                    end
                  }
                end
              }

              if share_ratio_answer.size > 0 && share_ratio.size > 0
                if share_ratio.standard_deviation !=0
                  share_ratio_answer.each{|sr_answer|
                    each_trans_sr_standardized.push((sr_answer-share_ratio.avg)/share_ratio.standard_deviation)
                    all_sr.push((sr_answer-share_ratio.avg)/share_ratio.standard_deviation)
                  }
                else
                  # 標準偏差が0ということはすべてのshare_ratioの値が同じとき
                  share_ratio_answer.each{|sr_answer|
                    each_trans_sr_standardized.push(0)
                  }
                end

                all_sr_divide_reachable.push(each_trans_sr_standardized.avg.to_f/reachable_node_num_arr.avg.to_f)
                all_reachable_target.push(reachable_node_num_arr.avg)
                pp "ファイル書き込み"
                print_line= transgraph_itr.to_s+","+reachable_node_num_arr.avg.to_s+","+each_trans_sr_standardized.avg.to_s+","+kvstring
                pp print_line
                # File.open(output_folder+"precision/features_#{language}.csv", "a") do |io| #ファイルあるなら末尾追記
                io.puts print_line
                # end

              end

            end #一言語での全てのトランスグラフ
            denominator=all_sr_divide_reachable.inject {|sum, n| sum + n }
            numerator=0
            all_reachable_target.each{|reachable_target|
              numerator += 1/reachable_target
            }
            pp numerator.to_f/all_reachable_target.size.to_f
            # io_all.puts "#{language},#{answer_type},#{denominator/numerator},#{denominator},#{numerator},#{numerator.to_f/all_reachable_target.size.to_f}"
            io_all.puts "#{language},#{answer_type},#{numerator.to_f/all_reachable_target.size.to_f}"
            io_all_standardized_sr.puts "#{language},#{answer_type},#{all_sr.avg}"
          end
        }
      }
    end
  end
end
#



main
