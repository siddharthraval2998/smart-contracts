# -*- coding: utf-8 -*-
"""
Created on Fri Sep  3 00:48:33 2021

@author: siddh
"""



import datetime
import hashlib
import json
from flask import Flask, jsonify

# simple blockchain

# architecture build

class Blockchain:
        def __init__(self):
            #intitialize the chain
            self.chain = []
            # create genesis block
            self.create_block(proof = 1, prev_hash = "0") # sha needs strings
        
        
        def create_block(self, proof, prev_hash):
            block = {"index" : len(self.chain)+1 ,
                     "Timestamp" : str(datetime.datetime.now()), # strinigify for json compatibility
                     "proof" :proof,
                     "prev_hash" : prev_hash
                     # "data" : anything
                     }
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
                
        
# mining the blockchain

#creating web app to interact

app = Flask(__name__)
app.config["JSONIFY_PRETTYPRINT_REGULAR"] = False

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
    block = blockchain.create_block(proof = proof,prev_hash= prev_hash)
    response = {"message" : "New Block Mined BITCH!!",
                "index" : block["index"],
                "Timestamp" : block["Timestamp"],
                "proof" : block["proof"],
                "prev_hash" : block["prev_hash"]
                
                }
    return jsonify(response), 200 #status OK HTTP code



# displaying the full blockchain


@app.route("/get_chain",methods=["GET"])


def get_chain():
    response = {"chain" : blockchain.chain,
                "length" : len(blockchain.chain)}

    return jsonify(response), 200 #status OK HTTP code



# running the app
#0.0.0.0.0 used to make server externally visible
app.run(host = "0.0.0.0" ,port =5000)









































        
            
                
                