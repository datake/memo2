import numpy as np
import csv
from pprint import pprint
import networkx as nx
import os
from datetime import datetime
import time

# generate one transgraph
# node_a,node_p,node_b:the number of nodes of a transgraph(source-language,pivot-language,target-language)
def generate_transgraph(node_a,node_p,node_b,output_directory,transraph_id,edge_weight,source_target_type):
    weight=[]
    tmp=1
    # frequency distribution of the number of edges
    for i in range(1,31):
        tmp*=edge_weight
        weight.insert(0, tmp)

    weight = np.array(weight)
    weight = weight/weight.sum()
    list_edge=[]
    for i in range(1,len(weight)+1):
        list_edge.append(i)


    edge_ap=0
    edge_bp=0

    # edge_ap:the number of edges between source and pivot nodes
    # decide the appropreate number of nodes and edge.
    # The number of edge need to be larger than the number of nodes.
    # The number of edge has an upper limit.
    if node_a == 1 or node_p ==1 :
        edge_ap=np.max([node_a,node_p])
    else:
        while edge_ap<np.max([node_a,node_p]) or edge_ap>node_a*node_p:
            list_edge_range=list_edge[np.max([node_a,node_p]):-1]
            weight_range=weight[np.max([node_a,node_p]):-1]
            weight_range = weight_range/weight_range.sum()
            edge_ap = np.random.choice(list_edge_range,p=weight_range)


    # edge_bp:the number of edges between target and pivot nodes
    if node_b == 1 or node_p ==1 :
        edge_bp=np.max([node_b,node_p])
    else:
        while edge_bp<np.max([node_b,node_p]) or edge_bp>node_b*node_p:
            list_edge_range=list_edge[np.max([node_b,node_p]):-1]
            weight_range=weight[np.max([node_b,node_p]):-1]
            weight_range = weight_range/weight_range.sum()
            edge_bp = np.random.choice(list_edge_range,p=weight_range)


    loop_count=0
    # Before here,the number of each node and the number of each edge is simulated.
    # After here,we will simulate how to connect edges.(using networkx)
    # rule1:Every node has one or more edges.
    # rule2:Every pivot node has to be conneted to source node and target node.
    # rule3:One transgraph must not be divided.

    while True:
        loop_count+=1
        G=nx.DiGraph()

        for i in range(node_p):
            G.add_node("p-"+str(i),lang='language_P',langP='1',langA='0',langB='0')

        for i in range(node_a):
            G.add_node("a-"+str(i),lang='language_A',langA='1',langB='0')

        for i in range(node_b):
            G.add_node("b-"+str(i),lang='language_B',langB='1',langA='0')

        dict_ap={}
        dict_bp={}
        while len(dict_ap)<edge_ap:
            tmp_a=np.random.randint(0,node_a)
            tmp_p=np.random.randint(0,node_p)
            G.add_edge("a-"+str(tmp_a),"p-"+str(tmp_p))
            dict_ap[str(tmp_a)+str(tmp_p)] = 1

        while len(dict_bp)<edge_bp:
            tmp_p=np.random.randint(0,node_p)
            tmp_b=np.random.randint(0,node_b)
            G.add_edge("p-"+str(tmp_p),"b-"+str(tmp_b))
            dict_bp[str(tmp_p)+str(tmp_b)] = 1

        if loop_count>20000:
            #it takes too long time to generate this dummy data
            with open("dummy_transgraph/fail_log.csv", "a") as io_csv2:
                io_csv2.write("a:"+str(node_a)+",p:"+str(node_p)+",b:"+str(node_b)+",a-p:"+str(edge_ap)+",b-p"+str(edge_bp)+"\n")
            return -1


        count_subgraph=0
        dict_node_a={}
        dict_node_b={}
        dict_node_p={}
        graphs = nx.connected_component_subgraphs(G.to_undirected())

        list_node_a_name=[]
        list_node_b_name=[]
        list_node_p_name=[]

        for subgraph in graphs:
            count_subgraph+=1
            if count_subgraph==1:
                lang=nx.get_node_attributes(subgraph,'lang')
                langP=nx.get_node_attributes(subgraph,'langP')
                langA=nx.get_node_attributes(subgraph,'langA')
                langB=nx.get_node_attributes(subgraph,'langB')

                for node in subgraph.nodes():
                    if lang[node]=='language_P':
                        set_A=set()
                        set_B=set()
                        name_node_a=""
                        name_node_b=""
                        name_node_p=""

                        is_connect_right_a=0
                        is_connect_right_b=0
                        dict_node_p[node]=1
                        for node_a_b in subgraph.neighbors(node):
                            if lang[node_a_b]=='language_A':
                                dict_node_a[node_a_b]=1
                                is_connect_right_a=1
                                set_A.add(node_a_b)
                            elif lang[node_a_b]=='language_B':
                                dict_node_b[node_a_b]=1
                                is_connect_right_b=1
                                set_B.add(node_a_b)

                        if is_connect_right_a==1 and is_connect_right_b == 1:
                            name_node_p=str(transraph_id)+"-"+node

                        last = len(set_A) - 1

                        for i, elem in enumerate(set_A):
                            if i == last:
                                name_node_a+= str(transraph_id)+"-"+elem
                            else:
                                name_node_a+= str(transraph_id)+"-"+elem
                                name_node_a+= ","

                        last = len(set_B) - 1
                        for i, elem in enumerate(set_B):
                            if i == last:
                                name_node_b+= str(transraph_id)+"-"+elem
                            else:
                                name_node_b+= str(transraph_id)+"-"+elem
                                name_node_b+= ","

                        list_node_a_name.append(name_node_a)
                        list_node_b_name.append(name_node_b)
                        list_node_p_name.append(name_node_p)


        # succeed in generating a dummy transgraph
        if nx.is_connected(G.to_undirected()) and is_connect_right_a==1 and is_connect_right_b == 1:

            # visualize a transgraph
            g_visualize = nx.to_agraph(G)
            output_new_dir=str(node_a)+"-"+str(node_p)+"-"+str(node_b)
            if not os.path.exists(output_directory+output_new_dir):
                os.makedirs(output_directory+output_new_dir)

            output_file=str(source_target_type)+str(len(dict_node_a))+"-"+str(len(dict_node_p))+"-"+str(len(dict_node_b))+"-"+str(len(dict_ap))+"-"+str(len(dict_bp))+"-"+str(transraph_id)
            g_visualize.draw(output_directory+output_new_dir+"/"+output_file+'.pdf',prog='dot')

            # csv output
            with open("dummy_transgraph/"+str(edge_weight)+"-"+str(source_target_type)+".csv", "a") as io_csv:
                for i, elem_p in enumerate(list_node_p_name):
                    io_csv.write("\""+str(edge_weight)+"-"+str(source_target_type)+list_node_p_name[i]+"\",\""+str(edge_weight)+"-"+str(source_target_type)+list_node_a_name[i]+"\",\""+str(edge_weight)+"-"+str(source_target_type)+list_node_b_name[i]+"\"\n")

            return 1


def call_generate_transgraph():
    source_target_node_num_type=[1,2,3]
    # the number of transgraphs that you will generate
    NUMBER_OF_TRANSGRAPH = 1000

    # When edge_weight is larger, you can get transgraphs which have less edges.
    for edge_weight in [1, 1.5, 2, 2.5, 3.0]:
        for source_target_type in source_target_node_num_type:
            transraph_id=0
            output_directory="dummy_transgraph/" +str(edge_weight)+"-"+str(source_target_type)+"/"
            while transraph_id < NUMBER_OF_TRANSGRAPH:
                list_node=[]
                # This weight is roughly culcurated from real dictionary
                # This weight represents the distribution of the number of source and target nodes
                if source_target_type==1:
                    # the number of source and target nodes is large
                    weight_source_target = [0.08406779661,0.186440678,0.1844067797,0.1410169492,0.1186440678,0.0786440678,0.05355932203,0.04406779661,0.02983050847,0.01559322034,0.01898305085,0.01016949153,0.007457627119,0.003389830508,0.003389830508,0.003389830508,0.002711864407,0.002711864407,0.0006779661017,0.001355932203,0.002711864407,0.0006779661017,0.001355932203,0.001355932203,0.001355932203,0.001355932203,0.0006779661017,0.0006779661017]
                elif source_target_type==2:
                    # the number of source and target nodes is middle
                    weight_source_target = [0.4049967655,0.3542517914,0.1412188337,0.0555594023,0.01811177552,0.01334188067,0.004073770308,0.002091867002,0.001946591574,0.0009556399212,0.0004415011038,0.0005494505495,0.0004415011038,0.0004415011038]
                elif source_target_type==3:
                    # the number of source and target nodes is small
                    weight_source_target = [0.1056383507,0.3125113362,0.2056782609,0.10535257,0.05870156492,0.02804858334,0.01892721786,0.01144366519,0.005162798045,0.004994044381,0.0003389830508,0.001060350956,0.001703762339,0.001747164143,0.0006868131868,0.0001694915254,0.00016949152,0.0001694915254,0.00016949152,0.0001694915254,0.00016949152,0.00016949152,0.0006868131868,0.00016949152,0.00016949152,0.00016949152,0.00016949152,0.00016949152]

                weight_source_target = np.array(weight_source_target)
                weight_source_target = weight_source_target/weight_source_target.sum()
                for i in range(1,len(weight_source_target)+1):
                    list_node.append(i)

                node_a = np.random.choice(list_node,p=weight_source_target)
                node_b = np.random.choice(list_node,p=weight_source_target)


                # This weight is roughly culcurated from real dictionary
                # This weight represents the distribution of the number of pivot nodes(FIX)
                weight_pivot = [0,0.7768958627,0.1542562061,0.03509816081,0.01779913524,0.007474975851,0.002426599238,0.001526246866,0.002923928604,0.0002711864407,0.0006497320378,0.0001355932203,0,0.0001355932203,0,0.0001355932203,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
                weight_pivot = np.array(weight_pivot)
                weight_pivot = weight_pivot/weight_pivot.sum()

                list_node=[]
                for i in range(1,len(weight_pivot)+1):
                    list_node.append(i)

                node_p = np.random.choice(list_node,p=weight_pivot)


                print("transgraph_id:"+str(transraph_id)+",node_a:"+str(node_a)+",node_b:"+str(node_b)+",node_p:"+str(node_p))
                if generate_transgraph(node_a,node_p,node_b,output_directory,transraph_id,edge_weight,source_target_type)==1:
                    transraph_id+=1

call_generate_transgraph()
