require 'rgl/base'
require 'rgl/adjacency'
require 'rgl/connected_components'
require 'csv'
require 'pp'
require 'logger'
require 'set'
require 'rgl/dot'
require 'fileutils'

# LANG_A="Uy_"
# LANG_B="Kz_"
# LANG_P="Zh_"
# LANG_A="Mnk_"
# LANG_B="Zsm_"
# LANG_P="Ind_"
LANG_A="A_"
LANG_B="B_"
LANG_P="P_"

def main
 get_csv_dot_of_connected_component
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
    CSV.foreach(input_filename) do |row|
      if row.size  == 3
        array_of_a = split_comma_to_array(row[1])
        array_of_b  = split_comma_to_array(row[2])
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

  def dispName()
    # print(@name, "¥n")
  end
end

class Answer
  def initialize(answer_filename)
    @answer = {}
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

def split_comma_to_array (text)
  # text=text.gsub(/"/, '')
  lang_arr=text.split(",")
  return lang_arr
end


def get_csv_dot_of_connected_component
# # =begin
#   which_lang="simulation"
#   input_filename="input/#{which_lang}_data.csv"
#   etc_folder="image/"
#   answer_filename="1-1-simulation/csv/simulation.csv"
# # =end

# =begin
  # languages=["0-8","1-0","1-2","1-5","1-8","2-0","2-2","2-5","2-8","3-0"]
  # languages=["0-8","1-0","1-5","1-8","2-0"]
  # languages=["2-5","2-8"]
  languages=["1-0-1","1-0-2","1-0-3","1-5-1","1-5-2","1-5-3","2-0-1","2-0-2","2-0-3"]

  languages.each{|which_lang|
    # input_folder="generate_transgraph/simulation_data-#{which_lang}.csv"
    input_folder="partition/#{which_lang}/"
    input_filename="input/simulation_data-#{which_lang}.csv"
    etc_folder="image/etc/#{which_lang}/"
    jpg_folder="image/jpg/#{which_lang}/"
    # output_each_trans_filename="image/jpg/#{which_lang}/"
    answer_filename="result/csv/#{which_lang}.csv"

    dirname = File.dirname(etc_folder)
    FileUtils::mkdir_p "#{etc_folder}dot/"
    FileUtils::mkdir_p "#{etc_folder}csv/"
    FileUtils::mkdir_p "image/etc/#{which_lang}/"
    FileUtils::mkdir_p "image/jpg/#{which_lang}/"

# =end





  transgraph = Transgraph.new(input_filename)
  answer = Answer.new(answer_filename)

  # 空の有向グラフを作る
  g  = RGL::DirectedAdjacencyGraph.new

  transgraph_count=0

  transgraph.pivot.each{|piv|
    tmp_p=piv[0]
    g.add_vertex(tmp_p)

    piv[1][0].each{|tmp_a|
      g.add_vertex("Ja-#{tmp_a}")
      g.add_edge("En-#{tmp_p}","Ja-#{tmp_a}")
    }
    piv[1][1].each{|tmp_b|
      g.add_vertex("De-#{tmp_b}")
      g.add_edge("En-#{tmp_p}","De-#{tmp_b}")
    }
    transgraph_count+=1
  }

  passed_transgraphs = []

  # 「トランスグラフのpivotが2以上、ノードが4以上」という条件を満たしたトランスグラフをpassed_transgraphsという配列にいれる
  # each_connected_componentが接続するサブグラフを返す
  g.to_undirected.each_connected_component { |connected_component|
    count_pivot=0
    if connected_component.size>=4
      connected_component.each{|c|
        if c.start_with?("En-")
          count_pivot+=1
        end
      }
      # マルダンのアプリケーションでパスするトランスグラフ
      if count_pivot>1
        passed_transgraphs <<  connected_component
      end
    end

  }

  pp passed_transgraphs
  # ファイル出力するものを選別
  # pivotだけ出力編
  passed_pivot=[]
  passed_transgraphs.each{|passed_transgraph|
    passed_transgraph.each{|node|
      if node.start_with?("En-")
        passed_pivot << node[3 .. -1] #En-以降の文字列を入れる
      end
    }
  }
  passed_pivot.sort!
  #transgraph情報をファイル出力
  i=0
  i_filecount=0
  output_transgraph=[]
  passed_transgraphs.each{|passed_transgraph|
    pp passed_transgraph
    File.open("#{etc_folder}dot/#{i_filecount}.dot", "w") do |io|
      File.open("#{etc_folder}csv/#{i_filecount}.csv", "w") do |io2|
        io.puts "digraph #{i} {"
        io.puts "graph [rankdir = LR];"
        passed_transgraph.each{|node|


        #答えペアに色付け
        if node.start_with?("Ja-")
          node_a=node[3 .. -1] #Aノード
          if answer.answer[node_a] && transgraph.lang_a_b[node_a]
            answerandb =answer.answer[node_a] & transgraph.lang_a_b[node_a]
            if ! answerandb.empty?
              color = "%06x" % (rand * 0xffffff)
              io.puts "\"#{LANG_A}#{node_a}\" [penwidth=5 color = \"\##{color}\"];"
              answerandb.each{|node_b|
                io.puts "\"#{LANG_B}#{node_b}\" [penwidth=5 color = \"\##{color}\"];"
                io.puts "\"#{LANG_A}#{node_a}\"->\"#{LANG_B}#{node_b}\" [style = dashed color = \"\##{color}\" dir = none];"
              }
              has_answer=1
            end
          end
        end




          if node.start_with?("En-")
            tmp_pivot=node[3 .. -1]
            output_transgraph[i]  = RGL::DirectedAdjacencyGraph.new
            pp tmp_pivot
            io2.print "\"#{tmp_pivot}\",\""
            # 英->日
            transgraph.lang_p_a[tmp_pivot].each_with_index{|tmp_ja,index|
              output_transgraph[i].add_vertex(tmp_ja)
              output_transgraph[i].add_edge(tmp_pivot,tmp_ja)
              io.puts "\"#{LANG_A}#{tmp_ja}\"->\"#{LANG_P}#{tmp_pivot}\";"
              if index==transgraph.lang_p_a[tmp_pivot].size-1
                io2.print "#{tmp_ja}\",\""
              else
                io2.print "#{tmp_ja},"
              end
            }

            # 英->独
            transgraph.lang_p_b[tmp_pivot].each_with_index{|tmp_de,index|
              output_transgraph[i].add_vertex(tmp_de)
              output_transgraph[i].add_edge(tmp_pivot,tmp_de)
              #
              io.puts "\"#{LANG_P}#{tmp_pivot}\"->\"#{LANG_B}#{tmp_de}\";"
              if index==transgraph.lang_p_b[tmp_pivot].size-1
                io2.puts "#{tmp_de}\""
              else
                io2.print "#{tmp_de},"
              end
              # sleep(5)
            }
            i=i+1
          end
        }
        io.puts "}"
      end
    end
    system( "dot -Tjpg '#{etc_folder}dot/#{i_filecount}.dot' -o #{jpg_folder}/#{i_filecount}.jpg" )

    i_filecount=i_filecount+1
  }
}
end



main
