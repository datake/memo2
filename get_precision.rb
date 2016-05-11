require 'csv'
require 'pp'
require 'logger'

def main
  get_precision_from_1dict
  # convert_from_mardan_1to1
  # convert_from_mardan_1to1
  # get_precision_from_zukind
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


def get_precision_from_1dict

  # languages = ["1-0","1-5","2","2-2","2-5","2-8"]
  # languages=["1-0-1","1-0-2","1-0-3","1-5-1","1-5-2","1-5-3","2-0-1","2-0-2","2-0-3"]
  languages=["1-0-1","1-0-2","1-0-3","1-5-1","1-5-2","1-5-3","2-0-1","2-0-2","2-0-3","2-5-1","2-5-2","2-5-3"]


  # edge_slope="2-0"
  # answer_types=["type-low","type-middle","type-high","same_num"]
  # answer_types=["u20","u40","u50","u60","u70","u80","u90","u100"]
  answer_types=["randum"]
  t = Time.now
  strTime = t.strftime("%B-%d-%H-%M-%S")
  output_all_precision="precision/precision_all_#{strTime}.csv"

  File.open(output_all_precision, "w") do |io_all|
    languages.each{|language|
      answer_types.each{|answer_type|
        answer_filename="answer/#{answer_type}/#{language}.csv"
        result_filename="result/csv/#{language}.csv"
        max=9999 #Indのときだけ0からはじめる
        min=0


        output_filename="precision/#{language}_#{answer_type}_precision.csv"

        answer = Answer.new(answer_filename)
        # pp answer
        unregistered_num=0;
        precisions=Array.new#precisionは作成した辞書のうち正しい割合
        #出力結果の検証
        File.open(output_filename, "w") do |io|
          # for num in min .. max do
          begin
            CSV.foreach(result_filename) do |rows|
              #TODO:正解辞書に答えがあるか確認 done
              pp rows
              is_true=0
              is_false=0
              is_not_included=0
              if answer.answer.has_key?(rows[0]) &&  answer.answer_head_trans.has_key?(rows[1])
                if answer.answer[rows[0]] && answer.answer[rows[0]].include?(rows[1])
                  is_true=1
                elsif answer.answer_head_trans[rows[1]] && answer.answer_head_trans[rows[1]].include?(rows[0])
                  is_true=1
                else
                  is_false=1
                end
              else
                is_not_included=1
              end

              if is_true ==1
                io.puts(rows[0]+","+rows[1]+",1,0")
                precisions.push(1)
              elsif is_false ==1
                io.puts(rows[0]+","+rows[1]+",0,1")
                precisions.push(0)
              end
            end
          rescue => error
            pp error.message
            next
          end
          # end
          #precision表示
          precision=precisions.inject(0.0){|r,i| r+=i }/precisions.size
          pp precision #precision平均
          io.puts precisions.inject(0.0){|r,i| r+=i }/precisions.size #precision平均
          io_all.puts "#{language},#{answer_type},#{precision}"
        end
      }
    }
  end
end

#実際のアプリケーションで得られた1-1のtsvファイルをcsvファイルに変換
def convert_from_mardan_1to1
  # languages = ["JaToEn_EnToDe","JaToDe_DeToEn","JaToEn_JaToDe","Ind_Mnk_Zsm","Zh_Uy_Kz"]
  # language="JaToEn_EnToDe0105"
  language="simulation"
  languages.each{|language|
    output_filename="1-1/csv/"+language+".csv"
    if language=="Zh_Uy_Kz"
      oofile_num=1480
      # input_filename="partition_graph1210/"+language+"/"+language+"_subgraph_"
      input_folder="1-1/buffer2_zuk_1480/graph_"
    elsif language=="Ind_Mnk_Zsm"
      # oofile_num=192 品詞ありのトランスグラフだと192に分割
      oofile_num=253 #品詞なし
      input_folder="1-1/buffer2_Ind_Mnk_Zsm_253/graph_"
    elsif language=="JaToEn_EnToDe"
      oofile_num=456
      input_folder="1-1/buffer2_JaEn_EnDe_456/graph_"
    elsif language=="JaToEn_EnToDe0105"
      oofile_num=207
      input_folder="1-1/buffer2_JaToEn_EnToDe0105_207/graph_"
    elsif language=="JaToEn_JaToDe"
      oofile_num=404
      input_folder="1-1/buffer2_JaEn_JaDe_404/graph_"
    elsif language=="JaToDe_DeToEn"
      oofile_num=380
      input_folder="1-1/buffer2_JaDe_DeEn_380/graph_"
    elsif language=="simulation"
      oofile_num=1000
      input_folder="1-1-simulation/simulation/graph_"
      output_filename="1-1-simulation/csv/"+language+".csv"
    end



    precisions=Array.new#precisionは作成した辞書のうち正しい割合
    #出力結果の検証
    File.open(output_filename, "w") do |io|
      for num in 1 .. oofile_num do
        begin
          CSV.foreach(input_folder + num.to_s + ".oo", :col_sep => "\t") do |rows|
            is_true_false=-1 #1:正解,2:不正解,3:判定不能
            if answer.answer.has_key?(rows[1]) &&  answer.answer_head_trans.has_key?(rows[2])
              if answer.answer[rows[1]].include?(rows[2])
                is_true_false=1
              elsif answer.answer_head_trans[rows[2]].include?(rows[1])
                is_true_false=1
              else
                is_true_false=2
              end
            else
              is_true_false=3
            end

            io.puts(rows[1]+","+rows[2]+","+is_true_false.to_s)
          end
        rescue => error
          pp error.message
          next
        end
      end
      #precision表示
      # pp precisions.inject(0.0){|r,i| r+=i }/precisions.size #precision平均
      # io.puts precisions.inject(0.0){|r,i| r+=i }/precisions.size #precision平均
    end
    puts "done "+language
  }
end


main
