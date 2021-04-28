class connectionHistory {
  int fromNode;
  int toNode;
  int innovationNumber;

  ArrayList<Integer> innovationNumbers = new ArrayList<Integer>();//nomor inovasi dari koneksi genom yang pertama kali mengalami mutasi ini
// ini mewakili genom dan memungkinkan kita untuk menguji apakah genoeme lain sama
 // ini sebelum koneksi ini ditambahkan

  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  //constructor
  connectionHistory(int from, int to, int inno, ArrayList<Integer> innovationNos) {
    fromNode = from;
    toNode = to;
    innovationNumber = inno;
    innovationNumbers = (ArrayList)innovationNos.clone();
  }
  //---------------------------------------------------------------------------------------------------------------------------------------------------------
  //returns apakah genom cocok dengan genom asli dan hubungannya antara node yang sama
  boolean matches(Genome genome, Node from, Node to) {
    if (genome.genes.size() == innovationNumbers.size()) { //if - jumlah koneksi berbeda maka genoemnya tidak sama
      if (from.number == fromNode && to.number == toNode) {
        //selanjutnya periksa apakah semua nomor inovasi cocok dari genom
        for (int i = 0; i< genome.genes.size(); i++) {
          if (!innovationNumbers.contains(genome.genes.get(i).innovationNo)) {
            return false;
          }
        }

          // jika mencapai sejauh ini maka nomor inovasi sesuai dengan nomor inovasi gen dan koneksi antara node yang sama
          // jadi cocok yeeeeeeee ohohohoho
        return true;
      }
    }
    return false;
  }
}
