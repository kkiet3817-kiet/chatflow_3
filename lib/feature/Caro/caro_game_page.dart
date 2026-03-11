import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CaroGamePage extends StatefulWidget {
  final String roomId;
  final String currentUserId;
  final String opponentName;

  const CaroGamePage({
    super.key,
    required this.roomId,
    required this.currentUserId,
    required this.opponentName,
  });

  @override
  State<CaroGamePage> createState() => _CaroGamePageState();
}

class _CaroGamePageState extends State<CaroGamePage> {
  static const int gridSize = 15;
  List<int> board = List.filled(gridSize * gridSize, 0); // 0: trống, 1: X, 2: O
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late bool isPlayer1; // Player 1 là X, Player 2 là O
  String turnMessage = "Đang kết nối...";
  bool myTurn = false;
  int? lastMoveIndex;
  
  Timer? _timer;
  int _secondsRemaining = 90; // 1 phút 30 giây
  static const int maxTime = 90;

  @override
  void initState() {
    super.initState();
    // Phân định: ID nhỏ hơn cầm X (đi trước)
    isPlayer1 = widget.currentUserId.compareTo(widget.opponentName) < 0;
    _listenToGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _listenToGame() {
    _firestore.collection('caro_games').doc(widget.roomId).snapshots().listen((snapshot) {
      if (!mounted) return;
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data()!;
        List<dynamic> boardData = data['board'];
        
        setState(() {
          board = boardData.cast<int>();
          lastMoveIndex = data['lastMoveIndex'];
        });
        
        Timestamp? updatedAt = data['updatedAt'] as Timestamp?;
        if (updatedAt != null) {
          int elapsed = DateTime.now().difference(updatedAt.toDate()).inSeconds;
          _secondsRemaining = maxTime - elapsed;
          if (_secondsRemaining < 0) _secondsRemaining = 0;
        } else {
          _secondsRemaining = maxTime;
        }
        
        _updateTurnState(data['lastMoveBy']);
      } else {
        _syncToFirebase(isInitial: true);
      }
    });
  }

  void _updateTurnState(String? lastMoveBy) {
    if (lastMoveBy == null || lastMoveBy == "system") {
      myTurn = isPlayer1;
    } else {
      myTurn = lastMoveBy != widget.currentUserId;
    }

    setState(() {
      turnMessage = myTurn ? "Lượt của bạn" : "Lượt của ${widget.opponentName}";
    });
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          if (myTurn) _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hết giờ!"),
        content: const Text("Bạn đã quá thời gian suy nghĩ."),
        actions: [
          TextButton(onPressed: () {
            Navigator.pop(context);
            _syncToFirebase(isInitial: true);
          }, child: const Text("Ván mới"))
        ],
      ),
    );
  }

  void _onTap(int index) {
    if (!myTurn || board[index] != 0) return;
    
    setState(() {
      board[index] = isPlayer1 ? 1 : 2;
    });
    
    _syncToFirebase(moveIndex: index);
    
    if (_checkWin(index)) {
      _showWinDialog();
    }
  }

  bool _checkWin(int index) {
    int row = index ~/ gridSize;
    int col = index % gridSize;
    int player = board[index];

    return _checkDirection(row, col, 1, 0, player) || // Ngang
           _checkDirection(row, col, 0, 1, player) || // Dọc
           _checkDirection(row, col, 1, 1, player) || // Chéo chính
           _checkDirection(row, col, 1, -1, player);   // Chéo phụ
  }

  bool _checkDirection(int r, int c, int dr, int dc, int player) {
    int count = 1;
    for (int i = 1; i < 5; i++) {
      int nr = r + dr * i;
      int nc = c + dc * i;
      if (nr < 0 || nr >= gridSize || nc < 0 || nc >= gridSize || board[nr * gridSize + nc] != player) break;
      count++;
    }
    for (int i = 1; i < 5; i++) {
      int nr = r - dr * i;
      int nc = c - dc * i;
      if (nr < 0 || nr >= gridSize || nc < 0 || nc >= gridSize || board[nr * gridSize + nc] != player) break;
      count++;
    }
    return count >= 5;
  }

  void _syncToFirebase({bool isInitial = false, int? moveIndex}) {
    _firestore.collection('caro_games').doc(widget.roomId).set({
      'board': isInitial ? List.filled(gridSize * gridSize, 0) : board,
      'lastMoveBy': isInitial ? "system" : widget.currentUserId,
      'lastMoveIndex': moveIndex,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _showWinDialog() {
     showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Thắng cuộc!"),
        content: const Text("Chúc mừng, bạn đã dành chiến thắng!"),
        actions: [
          TextButton(onPressed: () {
            Navigator.pop(context);
            _syncToFirebase(isInitial: true);
          }, child: const Text("Chơi lại"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text("Đại Chiến Caro", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black26,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildPlayerStats(),
          const Expanded(
            child: SizedBox(),
          ),
          _buildBoard(),
          const Expanded(
            child: SizedBox(),
          ),
          _buildStatusInfo(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlayerStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _playerBox(widget.opponentName, !myTurn, !isPlayer1),
          _playerBox("Bạn", myTurn, isPlayer1),
        ],
      ),
    );
  }

  Widget _playerBox(String name, bool active, bool xPlayer) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? Colors.blue.withOpacity(0.2) : Colors.white10,
        borderRadius: BorderRadius.circular(15),
        border: active ? Border.all(color: Colors.blueAccent, width: 2) : null,
        boxShadow: active ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10)] : null,
      ),
      child: Column(
        children: [
          Text(name, style: TextStyle(color: active ? Colors.white : Colors.white60, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Icon(xPlayer ? Icons.close : Icons.radio_button_unchecked, color: xPlayer ? Colors.red : Colors.blue, size: 24),
          if (active) ...[
            const SizedBox(height: 8),
            Text("${_secondsRemaining}s", style: const TextStyle(color: Colors.orangeAccent, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          ]
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD4A373),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridSize,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
            ),
            itemCount: gridSize * gridSize,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _onTap(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEFAE0),
                    border: index == lastMoveIndex ? Border.all(color: Colors.orangeAccent, width: 2) : null,
                  ),
                  child: Center(
                    child: _buildMark(index),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMark(int index) {
    if (board[index] == 0) return const SizedBox();
    if (board[index] == 1) {
      return const Icon(Icons.close, color: Colors.red, size: 20);
    } else {
      return const Icon(Icons.radio_button_unchecked, color: Colors.blue, size: 18);
    }
  }

  Widget _buildStatusInfo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          decoration: BoxDecoration(
            color: myTurn ? Colors.green.withOpacity(0.2) : Colors.white10,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            turnMessage.toUpperCase(),
            style: TextStyle(
              color: myTurn ? Colors.greenAccent : Colors.white38,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 15),
        TextButton.icon(
          onPressed: () => _syncToFirebase(isInitial: true),
          icon: const Icon(Icons.refresh, color: Colors.white38),
          label: const Text("LÀM MỚI TRẬN ĐẤU", style: TextStyle(color: Colors.white38)),
        ),
      ],
    );
  }
}
