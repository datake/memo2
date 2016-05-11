# e*- encoding:utf-8 -*-
import networkx as nx
# import matplotlib.pyplot as plt
import pygraphviz as pgv
import csv
# import pydot
from pprint import pprint
# import pandas as pd
import numpy as np

MINIMUN_NODES=4
MINIMUN_PIVOT=2

def count_edge():


    input_filename_all="count_edge/number_of_edges.csv"

    with open(input_filename_all, 'w') as io_edge_all:
    # language="1-8"
        languages=["1-0","1-5","2-0","2-5"]
        source_target_kinds=[1,2,3]
        for source_target_kind in source_target_kinds:
            for language in languages:

                G=nx.Graph()
                # list_num_edge=np.array([])
                list_num_edge=[]

                output_edge_folder="count_edge/"

                input_filename="input/simulation_data-"+language+"-"+str(source_target_kind)+".csv"


                with open(input_filename, 'r') as f:
                    dataReader = csv.reader(f)
                    for row in dataReader:
                        # print row[0]
                        if len(row)==3:
                            G.add_node(row[0],lang='En')
                            # G.graph[row[0]]='English'
                            row1_separate =row[1].split(',')
                            row2_separate =row[2].split(',')
                            for lang_a in row1_separate:
                                G.add_node(lang_a,lang='Ja')
                                G.add_edge(lang_a,row[0])
                                # pprint(lang_a)

                            for lang_b in row2_separate:
                                G.add_node(lang_b,lang='De')
                                G.add_edge(lang_b,row[0])

                graphs = nx.connected_component_subgraphs(G)

                subgraph_count=0
                pass_subgraph_count=0


                with open(output_edge_folder+language+"-"+str(source_target_kind)+"_edge.csv", "w") as io_edge:
                    for subgraph in graphs:
                        lang=nx.get_node_attributes(subgraph,'lang') # <-この処理遅い

                        pivot_count=0
                        node_all = set()
                        node_a = set()
                        node_b = set()
                        node_p = set()
                        entoja_edge_num=0
                        entode_edge_num=0
                        all_edge_num=0

                        if MINIMUN_NODES <= len(subgraph):
                            print("*********************subgraph number:"+str(pass_subgraph_count)+"("+str(subgraph_count)+")***************************")
                            subgraph_count+=1
                            print("*********************subgraph node数:"+str(len(subgraph))+"***************************")
                            pprint(subgraph.nodes())
                            for node in subgraph.nodes():
                                pprint(node)
                                pprint(lang[node])
                                if lang[node]=='En':
                                    pivot_count+=1

                            if pivot_count >= MINIMUN_PIVOT:
                                # en_edge_num=pivot_count
                                # print("英語ノード数")
                                # pprint(pivot_count)
                                pass_subgraph_count+=1
                                print("総エッジ数")
                                pprint(len(subgraph.edges()))
                                all_edge_num=len(subgraph.edges())
                                for node in subgraph.nodes():
                                    if lang[node]=='En':
                                        pprint(node)
                                        for node_ja_de in subgraph.neighbors(node):
                                            if lang[node_ja_de]=='Ja':
                                                entoja_edge_num+=1
                                            elif lang[node_ja_de]=='De':
                                                entode_edge_num+=1

                                print("英語->日本語エッジ数")
                                pprint(entoja_edge_num)
                                print("英語->ドイツエッジ数")
                                pprint(entode_edge_num)
                                io_edge.write(str(subgraph_count-1)+","+str(all_edge_num)+","+str(entoja_edge_num)+","+str(entode_edge_num)+"\n")
                                list_num_edge.append(all_edge_num)
                                # np.append(list_num_edge, all_edge_num)
                                print(str(subgraph_count-1)+","+str(all_edge_num)+","+str(entoja_edge_num)+","+str(entode_edge_num)+"\n")
                print(np.average(list_num_edge))
                io_edge_all.write(language+","+str(source_target_kind)+","+str(np.average(list_num_edge) )+"\n")


def count_node():
    G=nx.Graph()
    output_filename_all="count_node/number_of_nodes.csv"

    with open(output_filename_all, 'w') as io_node_all:
        languages=["1-0","1-5","2-0","2-5"]
        source_target_kinds=[1,2,3]
        for language in languages:
            for source_target_kind in source_target_kinds:

                G=nx.Graph()
                list_num_node=[]
                all_node_num=[]

                output_edge_folder="count_edge/"

                input_filename="input/simulation_data-"+language+"-"+str(source_target_kind)+".csv"

                is_all_transgraph=0

                output_node_folder="count_node/"


                with open(input_filename, 'r') as f:
                    dataReader = csv.reader(f)
                    for row in dataReader:
                        # print row[0]
                        G.add_node(row[0],lang='En')
                        # G.graph[row[0]]='English'
                        row1_separate =row[1].split(',')
                        row2_separate =row[2].split(',')
                        for lang_a in row1_separate:
                            G.add_node(lang_a,lang='Ja')
                            G.add_edge(lang_a,row[0])
                            # pprint(lang_a)

                        for lang_b in row2_separate:
                            G.add_node(lang_b,lang='De')
                            G.add_edge(lang_b,row[0])
                            # pprint(lang_b)

                # f.close()


                graphs = nx.connected_component_subgraphs(G)

                subgraph_count=0
                pass_subgraph_count=0

                with open(output_node_folder+language+"-"+str(source_target_kind)+"-"+"node.csv", "w") as io_node:
                    for subgraph in graphs:
                        lang=nx.get_node_attributes(subgraph,'lang') # <-この処理遅い
                        # if len(subgraph)<30000: #大きいトランスグラフをとばす場合はコメントアウト外す
                        # ピボット数の制限
                        pivot_count=0
                        node_all = set()
                        node_a = set()
                        node_b = set()
                        node_p = set()
                        if is_all_transgraph==1:
                            print("*********************subgraph number:"+str(pass_subgraph_count)+"("+str(subgraph_count)+")***************************")
                            subgraph_count+=1
                            print("*********************subgraph node数:"+str(len(subgraph))+"***************************")
                            for node in subgraph.nodes():
                                if lang[node]=='En':
                                    pivot_count+=1

                            if pivot_count > 0:
                                pass_subgraph_count+=1
                                for node in subgraph.nodes():
                                    node_all.add(node)
                                    if lang[node]=='En':
                                        node_p.add(node)

                                    if lang[node]=='Ja':
                                        node_a.add(node)

                                    if lang[node]=='De':
                                        node_b.add(node)

                                pprint(len(node_all))
                                pprint(len(node_a))
                                pprint(len(node_p))
                                pprint(len(node_b))
                                io_node.write(str(len(node_all))+","+str(len(node_a))+","+str(len(node_p))+","+str(len(node_b))+"\n")
                        else:
                            if MINIMUN_NODES <= len(subgraph): #!!! ノード数の制限
                                print("*********************subgraph number:"+str(pass_subgraph_count)+"("+str(subgraph_count)+")***************************")
                                subgraph_count+=1
                                print("*********************subgraph node数:"+str(len(subgraph))+"***************************")
                                for node in subgraph.nodes():
                                    if lang[node]=='En':
                                        pivot_count+=1
                                if pivot_count >= MINIMUN_PIVOT:
                                    pass_subgraph_count+=1
                                    for node in subgraph.nodes():
                                        node_all.add(node)
                                        if lang[node]=='En':
                                            node_p.add(node)
                                        if lang[node]=='Ja':
                                            node_a.add(node)
                                        if lang[node]=='De':
                                            node_b.add(node)

                                    pprint(len(node_all))
                                    pprint(len(node_a))
                                    pprint(len(node_p))
                                    pprint(len(node_b))
                                    io_node.write(str(language)+","+str(source_target_kind)+","+str(len(node_all))+","+str(len(node_a))+","+str(len(node_p))+","+str(len(node_b))+"\n")
                                    list_num_node.append(len(node_all))
                io_node_all.write(language+","+str(source_target_kind)+","+str(np.average(list_num_node) )+"\n")


count_node()
count_edge()
