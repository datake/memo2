require 'csv'
require 'pp'
require 'logger'

def main
  #get_precision_from_1dict
  convert_from_mardan_1to1
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



#実際のアプリケーションで得られた1-1のtsvファイルをcsvファイルに変換
def convert_from_mardan_1to1

  # languages=["1-2"]
  # languages=["0-8","1-0","1-5","1-8","2-0"]
  # languages=["2"]
  languages=["2-5","2-8"]
  languages.each{|language|
    # output_filename="1-1/csv/"+language+".csv"

    oofile_num=1000
    input_folder="result/buffer2_#{language}/graph_"
    output_filename="result/csv/"+language+".csv"




    precisions=Array.new#precisionは作成した辞書のうち正しい割合
    #出力結果の検証
    File.open(output_filename, "w") do |io|
      for num in 1 .. oofile_num do
        begin
          CSV.foreach(input_folder + num.to_s + ".oo", :col_sep => "\t") do |rows|
            is_true_false=-1 #1:正解,2:不正解,3:判定不能


            io.puts(rows[1]+","+rows[2])
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
