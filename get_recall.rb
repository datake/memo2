require 'csv'
require 'pp'
require 'logger'

def main
  get_recall_from_1dict
  # convert_from_mardan_1to1
  # convert_from_mardan_1to1
  # get_recall_from_zukind
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


def get_recall_from_1dict

  # languages = ["1-0","1-5","2","2-2","2-5","2-8"]
  # languages=["1-0-1","1-0-2","1-0-3","1-5-1","1-5-2","1-5-3","2-0-1","2-0-2","2-0-3"]
  languages=["1-0-1","1-0-2","1-0-3","1-5-1","1-5-2","1-5-3","2-0-1","2-0-2","2-0-3","2-5-1","2-5-2","2-5-3"]


  # edge_slope="2-0"
  # answer_types=["type-low","type-middle","type-high","same_num"]
  answer_types=["u20","u40","u50","u60","u70","u80","u90","u100"]
  # answer_types=["randum"]
  t = Time.now
  strTime = t.strftime("%B-%d-%H-%M-%S")
  output_all_recall="recall/recall_all_#{strTime}.csv"

  File.open(output_all_recall, "w") do |io_all|
    languages.each{|language|
      answer_types.each{|answer_type|
        answer_filename="answer/#{answer_type}/#{language}.csv"
        result_filename="result/csv/#{language}.csv"
        max=9999 #Indのときだけ0からはじめる
        min=0


        output_filename="recall/#{language}_#{answer_type}_recall.csv"

        # answer = Answer.new(answer_filename)
        answer = Answer.new(result_filename)
        # pp answer
        unregistered_num=0;
        recalls=Array.new#recallは作成した辞書のうち正しい割合
        #出力結果の検証
        File.open(output_filename, "w") do |io|
          # for num in min .. max do
          begin
            # CSV.foreach(result_filename) do |rows|
            CSV.foreach(answer_filename) do |rows|
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
                recalls.push(1)
              elsif is_false ==1
                io.puts(rows[0]+","+rows[1]+",0,1")
                recalls.push(0)
              end
            end
          rescue => error
            pp error.message
            next
          end
          # end
          #recall表示
          recall=recalls.inject(0.0){|r,i| r+=i }/recalls.size
          pp recall #recall平均
          io.puts recalls.inject(0.0){|r,i| r+=i }/recalls.size #recall平均
          io_all.puts "#{language},#{answer_type},#{recall}"
        end
      }
    }
  end
end



main
