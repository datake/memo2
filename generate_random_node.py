import numpy as np
import networkx as nx
import csv
from pprint import pprint
import pygraphviz as pgv
import matplotlib.pyplot as plt
import os
from datetime import datetime
import time

#エッジを張る際の傾斜 #2,1.2,1.5,1.8,2.0,1.0

def generate_transgraph(node_a,node_p,node_b,output_directory,itr_count,EDGE_SLOPE,EDGE_SLOPE_STRING,source_target_kind):
    itr=[]
    # 実データの枝数に基づく分布
    # weight =[0.3783812933,0.2521690888,0.1451887865,0.06993896472,0.05019433731,0.02662702045,0.0161860435,0.01261468098,0.008239611842,0.006692367802,0.004658431193,0.003966963137,0.00233053026,0.001341815171,0.001616245302,0.001051670595,0.0009350355104,0.0009523962318,0.0002033898305,0.0002033898305,0.0002033898305,0.0002033898305,0.0005423728814,0.0002711864407,0.00006779661017,0.0002033898305,0.00006779661017,0.0002570694087,0.0001355932203,0.00006779661017,0.00006779661017,0.00006779661017]
    # 重みを適当に決めてみた
    weight=[]
    tmp=1
    for i in range(1,31):
        tmp*=EDGE_SLOPE
        weight.insert(0, tmp)
    # 重みを適当に決めてみた end
    weight = np.array(weight)
    weight = weight/weight.sum()
    for i in range(1,len(weight)+1):
        itr.append(i)

    n=10
    # output_directory="generate_transgraph/graph/"
    is_loop_end=0
    # 注意:枝の数もランダムにした
    for edge_ap in range(30):#range(np.max([node_a,node_p]), node_a*node_p):
        edge_ap=0
        edge_bp=0
        if is_loop_end==1:
            break
        for edge_bp in range(30): #range(np.max([node_b,node_p]), node_b*node_p):
            if is_loop_end==1:
                break
            #a-pのエッジ
            if np.max([node_a,node_p])== node_a*node_p :
                edge_ap=np.max([node_a,node_p])
            else:
                #次のはランダムで可能な枝数の選択を一様ランダム
                # edge_ap=np.random.randint(np.max([node_a,node_p]), node_a*node_p +1) #np.max([node_a,node_p])からnode_a*node_p まで
                while True:
                    edge_ap = np.random.choice(itr,p=weight)
                    # weight_tmp=weight[np.max([node_a,node_p]):node_a*node_p]/weight[np.max([node_a,node_p]):node_a*node_p].sum()
                    # edge_ap = np.random.choice(itr[np.max([node_a,node_p]):node_a*node_p],p=weight_tmp)
                    if edge_ap>=np.max([node_a,node_p]) and edge_ap<=node_a*node_p:
                        break

                #重み付きで枝数決める
                # weight_edge_ap=weight[np.max([node_a,node_p]):node_a*node_p +1]
                # weight_edge_ap = weight_edge_ap/weight_edge_ap.sum()
                # edge_ap = np.random.choice(itr[np.max([node_a,node_p]):node_a*node_p +1],p=weight_edge_ap)

            #b-pのエッジ
            if np.max([node_b,node_p])== node_b*node_p :
                edge_bp=np.max([node_b,node_p])
            else:
                # edge_bp=np.random.randint(np.max([node_b,node_p]), node_b*node_p +1)
                while True:
                    edge_bp = np.random.choice(itr,p=weight)
                    # weight_tmp=weight[np.max([node_b,node_p]):node_b*node_p]/weight[np.max([node_b,node_p]):node_b*node_p].sum()
                    # edge_bp = np.random.choice(itr[np.max([node_b,node_p]):node_b*node_p],p=weight_tmp)
                    if edge_bp>=np.max([node_b,node_p]) and edge_bp<=node_b*node_p:
                        break
                #重み付きで枝数決める
                # weight_edge_bp=weight[np.max([node_a,node_p]):node_a*node_p +1]
                # weight_edge_bp = weight_edge_bp/weight_edge_bp.sum()
                # edge_bp = np.random.choice(itr[np.max([node_a,node_p]):node_a*node_p +1],p=weight_edge_bp)

            condition=  edge_ap>= node_a and edge_bp>= node_b and edge_ap>= node_p and edge_bp>= node_p #ノード数とエッジの関係
            condition = condition and (node_a*node_p)>=edge_ap and (node_b*node_p)>=edge_bp #これ以上はる枝がない
            # print("a,p,b:"+str(node_a)+","+str(node_p)+","+str(node_b))
            # print("a-p,p-b:"+str(edge_ap)+","+str(edge_bp))

            if condition:
                tmp=0
                while True:
                    G=nx.DiGraph()

                    # ピボット作成
                    # for i in range(1,node_p+1):
                    for i in range(node_p):
                        G.add_node("p-"+str(i),lang='language_P',langP='1',langA='0',langB='0')
                        # print("p-"+str(i))


                    #ノード作成
                    # for i in range(1,node_a+1):
                    for i in range(node_a):
                        G.add_node("a-"+str(i),lang='language_A',langA='1',langB='0')
                        # print("a-"+str(i))


                    # for i in range(1,node_b+1):
                    for i in range(node_b):
                        G.add_node("b-"+str(i),lang='language_B',langB='1',langA='0')
                        # print("b-"+str(i))

                    tmp+=1

                    #AとP
                    # for i in range(np.min([node_a,node_p]),edge_ap):
                    dict_ap={}
                    dict_bp={}
                    while len(dict_ap)<edge_ap:
                        # pprint(dict_ap)
                        tmp_a=np.random.randint(0,node_a)
                        tmp_p=np.random.randint(0,node_p)
                        # tmp_a=1
                        # tmp_p=1
                        G.add_edge("a-"+str(tmp_a),"p-"+str(tmp_p))
                        # print("a-"+str(tmp_a),"p-"+str(tmp_p))
                        dict_ap[str(tmp_a)+str(tmp_p)] = 1

                    #BとP
                    # for i in range(np.min([node_b,node_p]),edge_bp):
                    while len(dict_bp)<edge_bp:
                        # pprint(dict_bp)

                        tmp_p=np.random.randint(0,node_p)
                        tmp_b=np.random.randint(0,node_b)
                        G.add_edge("p-"+str(tmp_p),"b-"+str(tmp_b))
                        # print("b-"+str(tmp_b),"p-"+str(tmp_p))
                        dict_bp[str(tmp_p)+str(tmp_b)] = 1



                    # condition=nx.is_connected(G.to_undirected())
                    if tmp>100:
                        print("グラフ作成断念")
                        is_loop_end=1
                        with open("generate_transgraph/fail_log.csv", "a") as io_csv2:
                            io_csv2.write("グラフ作成できず,"+str(itr_count)+"a,p,b:"+str(node_a)+","+str(node_p)+","+str(node_b)+",a-p,p-b:"+str(edge_ap)+","+str(edge_bp)+"\n")
                        return -1
                        break

                    # 任意のピボットと必ずAとBはつながる
                    # A,B,Pの個数確認
                    count_connected_component=0
                    condition=0
                    has_edge_pa=0
                    has_edge_pb=0
                    output_node_a=0
                    output_node_b=0
                    output_node_p=0
                    dict_node_a={}
                    dict_node_b={}
                    dict_node_p={}
                    graphs = nx.connected_component_subgraphs(G.to_undirected())
                    is_not_connect_right=0
                    # set_A=set()
                    # set_B=set()
                    #
                    list_node_a_name=[]
                    list_node_b_name=[]
                    list_node_p_name=[]
                    for subgraph in graphs:
                        count_connected_component+=1
                        if count_connected_component==1:
                            lang=nx.get_node_attributes(subgraph,'lang')
                            langP=nx.get_node_attributes(subgraph,'langP')
                            langA=nx.get_node_attributes(subgraph,'langA')
                            langB=nx.get_node_attributes(subgraph,'langB')

                            for node in subgraph.nodes():

                                if lang[node]=='language_P':
                                    set_A=set()
                                    set_B=set()
                                    string_node_a=""
                                    string_node_b=""
                                    string_node_p=""

                                    # pprint(node)
                                    is_connect_right_a=0
                                    is_connect_right_b=0
                                    dict_node_p[node]=1
                                    for node_a_b in subgraph.neighbors(node):
                                        if lang[node_a_b]=='language_A':
                                            has_edge_pa=1
                                            dict_node_a[node_a_b]=1
                                            is_connect_right_a=1
                                            # print("L173:")
                                            # print(node_a_b)
                                            set_A.add(node_a_b)
                                        elif lang[node_a_b]=='language_B':
                                            has_edge_pb=1
                                            dict_node_b[node_a_b]=1
                                            is_connect_right_b=1
                                            set_B.add(node_a_b)
                                    #ピボットごとに必ずAもBもついているか確認
                                    if is_connect_right_a==1 and is_connect_right_b == 1:
                                        # is_not_connect_right=
                                        # print("このピボットはAもBもついている")
                                        string_node_p=str(itr_count)+"-"+node
                                    else:
                                        is_not_connect_right=1

                                    last = len(set_A) - 1
                                    # print("set_A:")
                                    # pprint(set_A)
                                    for i, elem in enumerate(set_A):
                                        if i == last:
                                            string_node_a+= str(itr_count)+"-"+elem
                                        else:
                                            string_node_a+= str(itr_count)+"-"+elem
                                            string_node_a+= ","

                                    last = len(set_B) - 1
                                    for i, elem in enumerate(set_B):
                                        if i == last:
                                            string_node_b+= str(itr_count)+"-"+elem
                                        else:
                                            string_node_b+= str(itr_count)+"-"+elem
                                            string_node_b+= ","

                                    list_node_a_name.append(string_node_a)
                                    list_node_b_name.append(string_node_b)
                                    list_node_p_name.append(string_node_p)

                        # else:
                        #     print("一つのトランスグラフになってない")
                        #     # time.sleep(0.1)


                    if nx.is_connected(G.to_undirected()) and is_not_connect_right != 1:# and has_edge_pa ==1 and has_edge_pb == 1:#and G.number_of_nodes()==(node_a+node_b+node_p) and G.number_of_edges()== (edge_ap+edge_bp):
                        print("祝作成:"+str(itr_count))
                        # time.sleep(0.5)
                        g_visualize = nx.to_agraph(G)
                        output_new_dir=str(node_a)+"-"+str(node_p)+"-"+str(node_b)
                        if not os.path.exists(output_directory+output_new_dir):
                            os.makedirs(output_directory+output_new_dir)

                        # output_file=str(len(dict_node_a))+"-"+str(len(dict_node_p))+"-"+str(len(dict_node_b))+"-"+str(len(dict_ap))+"-"+str(len(dict_bp))+"-"+str(itr_count)+datetime(2014,1,2,3,4,5).strftime('%s')
                        output_file=str(source_target_kind)+str(len(dict_node_a))+"-"+str(len(dict_node_p))+"-"+str(len(dict_node_b))+"-"+str(len(dict_ap))+"-"+str(len(dict_bp))+"-"+str(itr_count)

                        g_visualize.draw(output_directory+output_new_dir+"/"+output_file+'.pdf',prog='dot')
                        with open("generate_transgraph/simulation_data-0202-"+EDGE_SLOPE_STRING+"-"+str(source_target_kind)+".csv", "a") as io_csv:
                            for i, elem_p in enumerate(list_node_p_name):
                                io_csv.write("\""+list_node_p_name[i]+"\",\""+list_node_a_name[i]+"\",\""+list_node_b_name[i]+"\"\n")

                        is_loop_end=1
                        return 1
                        break


            else:
                print("グラフ作成できず")
                with open("generate_transgraph/fail_log.csv", "a") as io_csv2:
                    io_csv2.write("グラフ作成できずL235,"+str(itr_count)+"a,p,b:"+str(node_a)+","+str(node_p)+","+str(node_b)+",a-p,p-b:"+str(edge_ap)+","+str(edge_bp)+"\n")

                continue




def print_all():
    n=7
    output_directory="generate_transgraph/0124/"
    for node_a in range(1,n+1):
        for node_b in range(1,n+1):
            for node_p in range(1,4):
                generate_transgraph(node_a,node_p,node_b,output_directory)


def weighted_selected():
    EDGE_SLOPE_STRINGS=["1-0","1-5","2-0","2-5"]
    # EDGE_SLOPES=["0.8","1.0","1.2","1.5","1.8","2.0","2.2","2.5","2.8","3.0"]
    # EDGE_SLOPES=["1.0","1.5","2.0","2.5"]
    source_target_kinds=[1,2,3]
    # with open("generate_transgraph/fail/fail_trans_a_p_b-0202-edge.csv",  mode='a') as io_csv2:

    for EDGE_SLOPE_STRING in EDGE_SLOPE_STRINGS:
        # for EDGE_SLOPE in EDGE_SLOPES:
        for source_target_kind in source_target_kinds:
            EDGE_SLOPE = float(EDGE_SLOPE_STRING.replace('-', '.'))
            itr_count=0
            output_directory="generate_transgraph/0202-edge-"+EDGE_SLOPE_STRING+"-"+str(source_target_kind)+"/"
            while itr_count<10000:
                itr=[]
                #全ての平均
                # weight = [0.2531605027,0.320774498,0.1713213992,0.08402242406,0.04440092051,0.02575478045,0.0149637045,0.01003017924,0.006021465853,0.004034759747,0.002254648857,0.00171581481,0.001427267648,0.00125859926,0.0006137083256,0.000406779661,0.0002711864407,0.0003389830508,0.00006779661017,0.0002033898305,0.0002711864407,0.00006779661017,0.0004103184951,0,0,0,0.00006779661017,0.00006779661017,0,0]
                #カザフ
                if source_target_kind==1:
                    weight = [0.08406779661,0.186440678,0.1844067797,0.1410169492,0.1186440678,0.0786440678,0.05355932203,0.04406779661,0.02983050847,0.01559322034,0.01898305085,0.01016949153,0.007457627119,0.003389830508,0.003389830508,0.003389830508,0.002711864407,0.002711864407,0.0006779661017,0.001355932203,0.002711864407,0.0006779661017,0.001355932203,0.001355932203,0.001355932203,0.001355932203,0.0006779661017,0.0006779661017]
                elif source_target_kind==2:
                    #1が頂点
                    weight = [0.4049967655,0.3542517914,0.1412188337,0.0555594023,0.01811177552,0.01334188067,0.004073770308,0.002091867002,0.001946591574,0.0009556399212,0.0004415011038,0.0005494505495,0.0004415011038,0.0004415011038]
                elif source_target_kind==3:
                    #2が頂点
                    weight = [0.1056383507,0.3125113362,0.2056782609,0.10535257,0.05870156492,0.02804858334,0.01892721786,0.01144366519,0.005162798045,0.004994044381,0.0003389830508,0.001060350956,0.001703762339,0.001747164143,0.0006868131868,0.0001694915254,0.00016949152,0.0001694915254,0.00016949152,0.0001694915254,0.00016949152,0.00016949152,0.0006868131868,0.00016949152,0.00016949152,0.00016949152,0.00016949152,0.00016949152]

                weight = np.array(weight)
                weight = weight/weight.sum()
                for i in range(1,len(weight)+1):
                    itr.append(i)

                node_a = np.random.choice(itr,p=weight)
                node_b = np.random.choice(itr,p=weight)

                itr=[]
                weight_pivot = [0,0.7768958627,0.1542562061,0.03509816081,0.01779913524,0.007474975851,0.002426599238,0.001526246866,0.002923928604,0.0002711864407,0.0006497320378,0.0001355932203,0,0.0001355932203,0,0.0001355932203,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
                weight_pivot = np.array(weight_pivot)
                weight_pivot = weight_pivot/weight_pivot.sum()
                for i in range(1,len(weight_pivot)+1):
                    itr.append(i)
                #重み付きランダム(ノード)
                node_p = np.random.choice(itr,p=weight_pivot)
                # generate_transgraph(node_a,node_p,node_b,output_directory)
                print("node_a:"+str(node_a)+",node_b:"+str(node_b)+",node_p:"+str(node_p))
                if generate_transgraph(node_a,node_p,node_b,output_directory,itr_count,EDGE_SLOPE,EDGE_SLOPE_STRING,source_target_kind)==1:
                    itr_count+=1
                    # with open("generate_transgraph/fail/fail_trans_a_p_b-0202-edge-"+EDGE_SLOPE_STRING+".csv", "a+") as io_csv2:
                    # io_csv2.write("グラフ作成できず,"+EDGE_SLOPE_STRING+str(itr_count)+"a,p,b:"+str(node_a)+","+str(node_p)+","+str(node_b)+"\n")

weighted_selected()
