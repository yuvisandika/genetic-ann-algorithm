class Genome {
  ArrayList<connectionGene> genes = new  ArrayList<connectionGene>();//daftar koneksi antar node yang mewakili NN
  ArrayList<Node> nodes = new ArrayList<Node>();//list of nodes
  int inputs;
  int outputs;
  int layers =2;
  int nextNode = 0;
  int biasNode;

  ArrayList<Node> network = new ArrayList<Node>();//daftar node dalam urutan yang perlu dipertimbangkan dalam NN
  //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Genome(int in, int out) {
    //set input number and output number
    inputs = in;
    outputs = out;

    //create input nodes
    for (int i = 0; i<inputs; i++) {
      nodes.add(new Node(i));
      nextNode ++;
      nodes.get(i).layer =0;
    }

    //create output nodes
    for (int i = 0; i < outputs; i++) {
      nodes.add(new Node(i+inputs));
      nodes.get(i+inputs).layer = 1;
      nextNode++;
    }

    nodes.add(new Node(nextNode));//bias node
    biasNode = nextNode; 
    nextNode++;
    nodes.get(biasNode).layer = 0;
  }



  //-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  //returns node dengan nomer yang cocok
  //kadang nodes ngga beraturan (NAMANYA JUGA EVOLUSI #LOGIC)
  Node getNode(int nodeNumber) {
    for (int i = 0; i < nodes.size(); i++) {
      if (nodes.get(i).number == nodeNumber) {
        return nodes.get(i);
      }
    }
    return null;
  }


  //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  //menambahkan koneksi keluar dari suatu node ke node itu sehingga dapat mengakses node berikutnya selama proses berjalan terus
  void connectNodes() {

    for (int i = 0; i< nodes.size(); i++) {//clear the connections
      nodes.get(i).outputConnections.clear();
    }

    for (int i = 0; i < genes.size(); i++) {//untuk setiap connectionGene 
      genes.get(i).fromNode.outputConnections.add(genes.get(i));//menambahkan ke node
    }
  }

  //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  //memasukkan nilai input ke dalam NN dan mengembalikan array output
  float[] feedForward(float[] inputValues) {
    //set outputs untuk input nodes
    for (int i =0; i < inputs; i++) {
      nodes.get(i).outputValue = inputValues[i];
    }
    nodes.get(biasNode).outputValue = 1;//output bias = 1

    for (int i = 0; i< network.size(); i++) {//untuk setiap node dalam jaringan terlibat (lihat kelas node untuk mengetahui apa yang dilakukannya)
      network.get(i).engage();
    }

    //outputnya adalah node [input] ke node [input + output-1]
    float[] outs = new float[outputs];
    for (int i = 0; i < outputs; i++) {
      outs[i] = nodes.get(inputs + i).outputValue;
    }

    for (int i = 0; i < nodes.size(); i++) {//reset semua node untuke lanjut (next feed forward)
      nodes.get(i).inputSum = 0;
    }

    return outs;
  }

  //----------------------------------------------------------------------------------------------------------------------------------------
  //mengatur NN sebagai daftar node untuk digunakan

  void generateNetwork() {
    connectNodes();
    network = new ArrayList<Node>();
    //untuk setiap layer tambahkan node di layer itu, karena layer tidak dapat terhubung ke diri mereka sendiri (tidak perlu memesan node dalam lapisan) #GOBLOK

    for (int l = 0; l< layers; l++) {//for - setiap layer
      for (int i = 0; i< nodes.size(); i++) {//for - setiap node
        if (nodes.get(i).layer == l) {//if node di dalam layer (node in layer)
          network.add(nodes.get(i));
        }
      }
    }
  }
  //-----------------------------------------------------------------------------------------------------------------------------------------
// mutasikan NN dengan menambahkan node baru
// melakukan ini dengan memilih koneksi acak dan menonaktifkannya kemudian 2 koneksi baru ditambahkan
// 1 antara input node dari koneksi yang dinonaktifkan dan node baru
// dan lainnya antara node baru dan output dari koneksi yang dinonaktifkan
// aaaaaaaaa
  void addNode(ArrayList<connectionHistory> innovationHistory) {
    //pilih koneksi acak untuk membuat node di antaranya (create node)
    if (genes.size() ==0) {
      addConnection(innovationHistory); 
      return;
    }
    int randomConnection = floor(random(genes.size()));

    while (genes.get(randomConnection).fromNode == nodes.get(biasNode) && genes.size() !=1 ) {//bias (dont disconnect bias)
      randomConnection = floor(random(genes.size()));
    }

    genes.get(randomConnection).enabled = false;//disable it

    int newNodeNo = nextNode;
    nodes.add(new Node(newNodeNo));
    nextNode ++;
    //tambahkan koneksi baru ke node baru dengan bobot 1 (weight = 1)
    int connectionInnovationNumber = getInnovationNumber(innovationHistory, genes.get(randomConnection).fromNode, getNode(newNodeNo));
    genes.add(new connectionGene(genes.get(randomConnection).fromNode, getNode(newNodeNo), 1, connectionInnovationNumber));


    connectionInnovationNumber = getInnovationNumber(innovationHistory, getNode(newNodeNo), genes.get(randomConnection).toNode);
    //tambahkan koneksi baru dari node baru dengan bobot yang sama dengan koneksi yang dinonaktifkan (disabled connection)
    genes.add(new connectionGene(getNode(newNodeNo), genes.get(randomConnection).toNode, genes.get(randomConnection).weight, connectionInnovationNumber));
    getNode(newNodeNo).layer = genes.get(randomConnection).fromNode.layer +1;


    connectionInnovationNumber = getInnovationNumber(innovationHistory, nodes.get(biasNode), getNode(newNodeNo));
    //hubungkan bias ke simpul baru dengan bobot 0  (weight = 0)
    genes.add(new connectionGene(nodes.get(biasNode), getNode(newNodeNo), 0, connectionInnovationNumber));

    // jika layer node baru sama dengan layer node output dari koneksi lama maka layer baru perlu dibuat
     // lebih akurat jumlah layer dari semua layer yang sama atau lebih besar dari node baru ini perlu ditambahkan
    if (getNode(newNodeNo).layer == genes.get(randomConnection).toNode.layer) {
      for (int i = 0; i< nodes.size() -1; i++) {//jangan di masukin  (dont include this newest node)
        if (nodes.get(i).layer >= getNode(newNodeNo).layer) {
          nodes.get(i).layer ++;
        }
      }
      layers ++;
    }
    connectNodes();
  }

  //------------------------------------------------------------------------------------------------------------------
  //menambahkan koneksi antara 2 node yang saat ini tidak terhubung ()
  void addConnection(ArrayList<connectionHistory> innovationHistory) {
    //kalo ngga bisa menambahkan koneksi ke jaringan yang terhubung sepenuhnya
    if (fullyConnected()) {
      println("connection failed");
      return;
    }


    //get random nodes
    int randomNode1 = floor(random(nodes.size())); 
    int randomNode2 = floor(random(nodes.size()));
    while (randomConnectionNodesAreShit(randomNode1, randomNode2)) {//sementara node acak tidak baik
      //get new ones
      randomNode1 = floor(random(nodes.size())); 
      randomNode2 = floor(random(nodes.size()));
    }
    int temp;
    if (nodes.get(randomNode1).layer > nodes.get(randomNode2).layer) {//jika node random pertama adalah setelah node kedua maka alihkan (switch)
      temp =randomNode2  ;
      randomNode2 = randomNode1;
      randomNode1 = temp;
    }    

// dapatkan nomor inovasi koneksi
// ini akan menjadi nomor baru jika tidak ada genom yang identik bermutasi dengan cara yang sama
    int connectionInnovationNumber = getInnovationNumber(innovationHistory, nodes.get(randomNode1), nodes.get(randomNode2));
    //add the connection random array

    genes.add(new connectionGene(nodes.get(randomNode1), nodes.get(randomNode2), random(-1, 1), connectionInnovationNumber));//ganti ini jadi kalo error kesini (katanya)
    connectNodes();
  }
  //-------------------------------------------------------------------------------------------------------------------------------------------
  boolean randomConnectionNodesAreShit(int r1, int r2) {
    if (nodes.get(r1).layer == nodes.get(r2).layer) return true; // if the nodes di layer yang sama
    if (nodes.get(r1).isConnectedTo(nodes.get(r2))) return true; //if the nodes sudah terkoneksi

    return false;
  }

  //-------------------------------------------------------------------------------------------------------------------------------------------
   // kembalikan nomor inovasi untuk mutasi baru
   // jika mutasi ini belum pernah terlihat sebelumnya maka akan diberikan nomor inovasi unik baru
   // jika mutasi ini cocok dengan mutasi sebelumnya maka akan diberikan nomor inovasi yang sama dengan yang sebelumnya
  int getInnovationNumber(ArrayList<connectionHistory> innovationHistory, Node from, Node to) {
    boolean isNew = true;
    int connectionInnovationNumber = nextConnectionNo;
    for (int i = 0; i < innovationHistory.size(); i++) {//for - setiap mutasi sebelumnya
      if (innovationHistory.get(i).matches(this, from, to)) {//if - kecocokan ketemu (jodoh)
        isNew = false;//its not a new mutation
        connectionInnovationNumber = innovationHistory.get(i).innovationNumber; //set - nomor inovasi sebagai nomor inovasi pertandingan (bingung ane)
        break;
      }
    }

    if (isNew) {//if - mutasi baru maka buat arrayList bilangan bulat yang mewakili keadaan genom saat ini
      ArrayList<Integer> innoNumbers = new ArrayList<Integer>();
      for (int i = 0; i< genes.size(); i++) {//set the innovation numbers
        innoNumbers.add(genes.get(i).innovationNo);
      }

      //kemudian tambahkan mutasi ini ke Riwayat inovasi
      innovationHistory.add(new connectionHistory(from.number, to.number, connectionInnovationNumber, innoNumbers));
      nextConnectionNo++;
    }
    return connectionInnovationNumber;
  }
  //----------------------------------------------------------------------------------------------------------------------------------------

  //return -  apakah jaringan terhubung sepenuhnya atau tidak
  boolean fullyConnected() {
    int maxConnections = 0;
    int[] nodesInLayers = new int[layers];//array yang menyimpan jumlah node di setiap lapisan
    //populate array
    for (int i =0; i< nodes.size(); i++) {
      nodesInLayers[nodes.get(i).layer] +=1;
    }

    // untuk setiap layer, jumlah koneksi maksimum adalah angka di layer ini * jumlah node di depannya
     // jadi mari kita tambahkan max untuk setiap layer bersama dan kemudian kita akan mendapatkan jumlah koneksi maksimum dalam jaringan
    for (int i = 0; i < layers-1; i++) {
      int nodesInFront = 0;
      for (int j = i+1; j < layers; j++) {//untuk setiap layer di depan layer ini
        nodesInFront += nodesInLayers[j];//add up nodes
      }

      maxConnections += nodesInLayers[i] * nodesInFront;
    }

    if (maxConnections == genes.size()) {//jika jumlah koneksi sama dengan jumlah maksimum koneksi yang mungkin maka penuh
      return true;
    }
    return false;
  }


  //-------------------------------------------------------------------------------------------------------------------------------
  //mutates the genome
  void mutate(ArrayList<connectionHistory> innovationHistory) {
    if (genes.size() ==0) {
      addConnection(innovationHistory);
    }

    float rand1 = random(1);
    if (rand1<0.8) { // 80% of the time mutate weights
      for (int i = 0; i< genes.size(); i++) {
        genes.get(i).mutateWeight();
      }
    }
    //5% of the time add a new connection
    float rand2 = random(1);
    if (rand2<0.08) {
      addConnection(innovationHistory);
    }


    //1% of the time add a node
    float rand3 = random(1);
    if (rand3<0.02) {
      addNode(innovationHistory);
    }
  }

  //---------------------------------------------------------------------------------------------------------------------------------
  //dipanggil ketika Genom ini lebih baik daripada orang tua lainnya
  Genome crossover(Genome parent2) {
    Genome child = new Genome(inputs, outputs, true);
    child.genes.clear();
    child.nodes.clear();
    child.layers = layers;
    child.nextNode = nextNode;
    child.biasNode = biasNode;
    ArrayList<connectionGene> childGenes = new ArrayList<connectionGene>();//daftar gen yang akan diwarisi dari orang tua
    ArrayList<Boolean> isEnabled = new ArrayList<Boolean>(); 
    //semua gen yang diwariskan
    for (int i = 0; i< genes.size(); i++) {
      boolean setEnabled = true;//apakah node ini pada anak akan diaktifkan

      int parent2gene = matchingGene(parent2, genes.get(i).innovationNo);
      if (parent2gene != -1) {//if - gen cocok
        if (!genes.get(i).enabled || !parent2.genes.get(parent2gene).enabled) {//if - salah satu gen yang cocok dinonaktifkan

          if (random(1) < 0.75) {//75% of the time disabel the childs gene
            setEnabled = false;
          }
        }
        float rand = random(1);
        if (rand<0.5) {
          childGenes.add(genes.get(i));

          //get gene from this fucker #aaGOBLOK
        } else {
          //get gene from parent2
          childGenes.add(parent2.genes.get(parent2gene));
        }
      } else {//disjoint or excess gene
        childGenes.add(genes.get(i));
        setEnabled = genes.get(i).enabled;
      }
      isEnabled.add(setEnabled);
    }


     // karena semua gen berlebih dan terpisahkan diwarisi dari induk yang lebih cocok (Genom ini) struktur anak tidak berbeda dari orangtua ini | dengan pengecualian koneksi aktif diaktifkan tetapi ini tidak akan mempengaruhi node
     // jadi semua node dapat diwarisi dari orangtua 
    for (int i = 0; i < nodes.size(); i++) {
      child.nodes.add(nodes.get(i).clone());
    }

    // clone semua koneksi sehingga mereka menghubungkan node baru anak-anaknya

    for ( int i =0; i<childGenes.size(); i++) {
      child.genes.add(childGenes.get(i).clone(child.getNode(childGenes.get(i).fromNode.number), child.getNode(childGenes.get(i).toNode.number)));
      child.genes.get(i).enabled = isEnabled.get(i);
    }

    child.connectNodes();
    return child;
  }

  //----------------------------------------------------------------------------------------------------------------------------------------
  //create an empty genome
  Genome(int in, int out, boolean crossover) {
    //set input number and output number
    inputs = in; 
    outputs = out;
  }
  //----------------------------------------------------------------------------------------------------------------------------------------
  //returns - apakah ada gen yang cocok dengan nomor inovasi input dalam genom input
  int matchingGene(Genome parent2, int innovationNumber) {
    for (int i =0; i < parent2.genes.size(); i++) {
      if (parent2.genes.get(i).innovationNo == innovationNumber) {
        return i;
      }
    }
    return -1; //no matching gene found 404
  }
  //----------------------------------------------------------------------------------------------------------------------------------------
  //mencetak info tentang genom ke konsol (prints out info)
  void printGenome() {
    println("Print genome  layers:", layers);  
    println("bias node: "  + biasNode);
    println("nodes");
    for (int i = 0; i < nodes.size(); i++) {
      print(nodes.get(i).number + ",");
    }
    println("Genes");
    for (int i = 0; i < genes.size(); i++) {//for each connectionGene 
      println("gene " + genes.get(i).innovationNo, "From node " + genes.get(i).fromNode.number, "To node " + genes.get(i).toNode.number, 
        "is enabled " +genes.get(i).enabled, "from layer " + genes.get(i).fromNode.layer, "to layer " + genes.get(i).toNode.layer, "weight: " + genes.get(i).weight);
    }

    println();
  }

  //----------------------------------------------------------------------------------------------------------------------------------------
  //returns a copy of this genome
  Genome clone() {

    Genome clone = new Genome(inputs, outputs, true);

    for (int i = 0; i < nodes.size(); i++) {//copy nodes
      clone.nodes.add(nodes.get(i).clone());
    }

    //copy all the connections sehingga  bisa menghubungkan klon node baru

    for ( int i =0; i<genes.size(); i++) {//copy genes
      clone.genes.add(genes.get(i).clone(clone.getNode(genes.get(i).fromNode.number), clone.getNode(genes.get(i).toNode.number)));
    }

    clone.layers = layers;
    clone.nextNode = nextNode;
    clone.biasNode = biasNode;
    clone.connectNodes();

    return clone;
  }
  //----------------------------------------------------------------------------------------------------------------------------------------
  //draw the genome on the screen (knn)
  void drawGenome(int startX, int startY, int w, int h) {
    //bisa sih tapi noob (bodo ah) 
    ArrayList<ArrayList<Node>> allNodes = new ArrayList<ArrayList<Node>>();
    ArrayList<PVector> nodePoses = new ArrayList<PVector>();
    ArrayList<Integer> nodeNumbers= new ArrayList<Integer>();

    //get -  posisi di layar bahwa setiap node seharusnya berada


    //split the nodes into layers
    for (int i = 0; i< layers; i++) {
      ArrayList<Node> temp = new ArrayList<Node>();
      for (int j = 0; j< nodes.size(); j++) {//for each node 
        if (nodes.get(j).layer == i ) {//check if it is in this layer
          temp.add(nodes.get(j)); //add it to this layer
        }
      }
      allNodes.add(temp);//add this layer to all nodes
    }

    //for - setiap layer menambahkan posisi node di layar ke node memiliki daftar array
    for (int i = 0; i < layers; i++) {
      fill(255, 0, 0);
      float x = startX + (float)((i)*w)/(float)(layers-1);
      for (int j = 0; j< allNodes.get(i).size(); j++) {//for the position in the layer
        float y = startY + ((float)(j + 1.0) * h)/(float)(allNodes.get(i).size() + 1.0);
        nodePoses.add(new PVector(x, y));
        nodeNumbers.add(allNodes.get(i).get(j).number);
        if(i == layers -1){
         println(i,j,x,y); 
          
          
        }
      }
    }

    //draw connections 
    stroke(0);
    strokeWeight(2);
    for (int i = 0; i< genes.size(); i++) {
      if (genes.get(i).enabled) {
        stroke(0);
      } else {
        stroke(100);
      }
      PVector from;
      PVector to;
      from = nodePoses.get(nodeNumbers.indexOf(genes.get(i).fromNode.number));
      to = nodePoses.get(nodeNumbers.indexOf(genes.get(i).toNode.number));
      if (genes.get(i).weight > 0) {
        stroke(255, 0, 0);
      } else {
        stroke(0, 0, 255);
      }
      strokeWeight(map(abs(genes.get(i).weight), 0, 1, 0, 5));
      line(from.x, from.y, to.x, to.y);
    }

    //draw nodes last so they appear ontop of the connection lines yeeee
    for (int i = 0; i < nodePoses.size(); i++) {
      fill(255);
      stroke(0);
      strokeWeight(1);
      ellipse(nodePoses.get(i).x, nodePoses.get(i).y, 20, 20);
      textSize(10);
      fill(0);
      textAlign(CENTER, CENTER);


      text(nodeNumbers.get(i), nodePoses.get(i).x, nodePoses.get(i).y);
    }
  }
}
