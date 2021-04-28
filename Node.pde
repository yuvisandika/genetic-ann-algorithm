class Node {
  int number;
  float inputSum = 0;//jumlah saat ini yaitu sebelum aktivasi (sum.i.e)
  float outputValue = 0; //setelah fungsi aktivasi diterapkan
  ArrayList<connectionGene> outputConnections = new ArrayList<connectionGene>();
  int layer = 0;
  PVector drawPos = new PVector();
  //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  //constructor
  Node(int no) {
    number = no;
  }

  //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  //node mengirimkan outputnya ke input dari node yang terhubung dengannya
  void engage() {
    if (layer!=0) {//tidak ada sigmoid untuk input dan bias
      outputValue = sigmoid(inputSum);
    }

    for (int i = 0; i< outputConnections.size(); i++) {//for each connection
      if (outputConnections.get(i).enabled) {//jangan lakukan apa-apa jika tidak diaktifkan
        outputConnections.get(i).toNode.inputSum += outputConnections.get(i).weight * outputValue;//tambahkan output bobot ke jumlah input dari node apa pun yang terhubung dengan node ini
      }
    }
 }
//----------------------------------------------------------------------------------------------------------------------------------------
//not used
  float stepFunction(float x) {
    if (x < 0) {
      return 0;
    } else {
      return 1;
    }
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//sigmoid activation function
  float sigmoid(float x) {
    float y = 1 / (1 + pow((float)Math.E, -4.9*x));
    return y;
  }
  //----------------------------------------------------------------------------------------------------------------------------------------------------------
  // mengembalikan apakah simpul ini terhubung ke simpul parameter
  // digunakan saat menambahkan koneksi baru
  boolean isConnectedTo(Node node) {
    if (node.layer == layer) {//nodes in the same layer cannot be connected blabla
      return false;
    }

    //you get it yeeee
    if (node.layer < layer) {
      for (int i = 0; i < node.outputConnections.size(); i++) {
        if (node.outputConnections.get(i).toNode == this) {
          return true;
        }
      }
    } else {
      for (int i = 0; i < outputConnections.size(); i++) {
        if (outputConnections.get(i).toNode == node) {
          return true;
        }
      }
    }

    return false;
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  //returns a copy of this node
  Node clone() {
    Node clone = new Node(number);
    clone.layer = layer;
    return clone;
  }
}
