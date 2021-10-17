# -*- coding: utf-8 -*-
"""
Created on Sat Sep 11 18:53:38 2021

@author: siddh
"""

import datetime
import hashlib
import json
from flask import Flask, jsonify, request
import requests
from uuid import uuid4
from urllib.parse import urlparse

# simple crypto currency

# building a genereal purose blockchain

class Blockchain:
        def __init__(self):
            #intitialize the chain
            self.chain = []
            self.transactions = [] #before creating a block!
            # create genesis block
            self.create_block(proof = 1, prev_hash = "0" ) # sha needs strings
            self.nodes = set() #since no ordering required
                        
        
        
        def create_block(self, proof, prev_hash):
            block = {"index" : len(self.chain)+1 ,
                     "Timestamp" : str(datetime.datetime.now()), # strinigify for json compatibility
                     "proof" :proof,
                     "prev_hash" : prev_hash,
                     "transactions": self.transactions
                     # "data" : anything
                     }
            self.transactions = [] # remove all transactions after entering into the block
            self.chain.append(block)
            return block
                     
            
        def get_prev_block(self):
                return self.chain[-1]
        
        
        def proof_of_work(self,prev_proof):
            new_proof = 1
            check_proof = False
            while check_proof is False:
                #mining problem
                hash_operation = hashlib.sha256(str(new_proof**2 - prev_proof**2).encode()).hexdigest()#make sure this operation is not symmetrical like +,* etc
                #testing the acceptance off proof, i.e. difficulty criteria
                if hash_operation[:4] == "0000": #upper bound excluded, thus 4 means 4 zeros
                    check_proof = True
                else:
                    new_proof += 1
            return new_proof

        #creating a hash function for uniformity
        def hash_function(self, block):
            #make dict to str  using json dumps 
            encoded_block = json.dumps(block,sort_keys=True).encode() #sha needs encoded
            return hashlib.sha256(encoded_block).hexdigest()
            
        
        def is_chain_valid(self,chain):
            prev_block = chain[0]
            block_index = 1 #looping variable
            while block_index < len(chain):
                #checks
                block = chain[block_index]
                if block["prev_hash"] != self.hash_function(prev_block):
                    return False
                prev_proof = prev_block["proof"]
                current_proof = block["proof"]
                hash_operation = hashlib.sha256(str(current_proof**2 - prev_proof**2).encode()).hexdigest()
                if hash_operation[:4] != "0000" :
                    return False
                prev_block = block
                block_index += 1
            return True
        
        def add__transaction(self,sender,reciever,amount):
            self.transactions.append({"sender":sender,
                                      "reciever":reciever,
                                      "amount":amount})
            prev_block = self.get_prev_block()
            return prev_block["index"] + 1 #will be the index of the next block to be mined
        
        def add_node(self, address):
            #parse the address
            parsed_url = urlparse(address)
            self.nodes.add(parsed_url.netloc) # .netlock to show the main identifier (127.0.0.1:5000)
            
            
        def replace_chain(self):
            network = self.nodes
            longest_chain = None
            max_length = len(self.chain)
            for node in network:
                response = requests.get(f'http://{node}/get_chain') #programatically get the response, while generalizing ip+port combo 
                if response.status_code == 200:
                    length = response.json()["length"]
                    chain = response.json()["chain"]
                    if length > max_length and self.is_chain_valid(chain):
                        max_length = length 
                        longest_chain = chain
            if longest_chain:
                self.chain = longest_chain
                return True
            return False
                        
# mining the blockchain

#creating web app to interact

app = Flask(__name__)
app.config["JSONIFY_PRETTYPRINT_REGULAR"] = False

#creating an address for the node on port 5000
#needed for block reward transaction and as a parameter in add_node function
#uuid4 will create a unique id for our node
node_address = str(uuid4()).replace("-","") #to remove -s


#create the blockchain instance

blockchain = Blockchain()

# mining a block

@app.route("/mine_block",methods=["GET"])


def mine_block():
    # get the previous proof
    prev_block = blockchain.get_prev_block()
    prev_proof = prev_block["proof"]
    proof = blockchain.proof_of_work(prev_proof)
    #get prev_hash
    prev_hash = blockchain.hash_function(prev_block)
    transactions = blockchain.add_transaction(sender = node_address,reciever = "Raval", amount = 6.9)
    block = blockchain.create_block(proof = proof,prev_hash= prev_hash,transactions = transactions)
    response = {"message" : "New Block Mined BITCH!!",
                "index" : block["index"],
                "Timestamp" : block["Timestamp"],
                "proof" : block["proof"],
                "prev_hash" : block["prev_hash"],
                "transactions": block["transactions"]
                
                }
    return jsonify(response), 200 #status OK HTTP code



# displaying the full blockchain


@app.route("/get_chain",methods=["GET"])


def get_chain():
    response = {"chain" : blockchain.chain,
                "length" : len(blockchain.chain)}

    return jsonify(response), 200 #status OK HTTP code


@app.route("/is_valid",methods=["GET"])

def is_valid():
    is_valid = blockchain.is_chain_valid(blockchain.chain)
    if is_valid:
        response = {"message":"All good, Houston"}
    else:
        response = {"message":"Someone fucked with the blockchain!"}
    return jsonify(response), 200


# Making a POST request 

@app.route("/add_transaction",methods=["POST"])
def add_transaction():
    json = requests.get_json()
    transaction_keys = ["sender","reciever","amount"]
    if not all (key in json for key in transaction_keys):
        return "some transaction elements missing" , 400 #bad request
    index = blockchain.add_transaction(json["sender"],json["reciever"],json["amount"])
    response = {"message": f"This transaction will be added to Block {index}"}
    return jsonify(response), 201 #successfully created
        

#decentralizing the blockchain

#connecting new nodes

@app.route("/connect_node",methods=["POST"])
def connect_node():
        json = requests.get_json()
        #add_node takes an address also
        nodes = json.get("nodes") # will get and return the addresses of the nodes in the network
        if nodes is None:
            return "No node", 400 
        for node in nodes:
            blockchain.add_node(node)
        response = {"message": "All nodes connected, Go Go GoTron. connected nodes are - " ,
                    "total_nodes":list(blockchain.nodes)} 
        return jsonify(response), 201
            
#replacing the chain by the longest chain if/when needed

@app.route("/replace_chain",methods=["GET"])

def replace_chain():
    is_chain_replaced = blockchain.is_chain_valid(blockchain.chain)
    if is_chain_replaced:
        response = {"message":"There was a fight, it wasn't the longest, alpha takeover.",
                    "new_chain": blockchain.chain}
    else:
        response = {"message":"Longest one in town!",
                    "actual_chain": blockchain.chain}
    return jsonify(response), 200


# running the app
#0.0.0.0.0 used to make server externally visible
app.run(host = "0.0.0.0" ,port =5000)
