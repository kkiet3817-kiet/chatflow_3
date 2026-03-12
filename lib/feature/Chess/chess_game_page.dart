import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chess/chess.dart' as chess_lib;

class ChessGamePage extends StatefulWidget {
  final String roomId;
  final String currentUserId;
  final String opponentName;

  const ChessGamePage({
    super.key,
    required this.roomId,
    required this.currentUserId,
    required this.opponentName,
  });

  @override
  State<ChessGamePage> createState() => _ChessGamePageState();
}

class _ChessGamePageState extends State<ChessGamePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChessBoardController _chessController = ChessBoardController();
  
  late bool isWhite;
  bool myTurn = false;
  Timer? _timer;
  int _secondsRemaining = 120;
  static const int maxTime = 120;
  bool _isGameOver = false;

  List<String> validMovesSquares = [];
  String? selectedSquare;

  @override
  void initState() {
    super.initState();
    isWhite = widget.currentUserId.compareTo(widget.opponentName) < 0;
    _listenToGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _playMoveSound() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }

  void _listenToGame() {
    _firestore.collection('chess_games').doc(widget.roomId).snapshots().listen((snapshot) {
      if (!mounted) return;
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data()!;
        
        // Kiểm tra trạng thái đầu hàng hoặc kết thúc đặc biệt
        if (data['status'] == 'resigned') {
          String winner = data['winner'];
          _showEndGameDialog("TRẬN ĐẤU KẾT THÚC", winner == widget.currentUserId ? "Đối thủ đã đầu hàng. Bạn thắng!" : "Bạn đã đầu hàng.");
          return;
        }

        if (data['lastMoveBy'] != widget.currentUserId) {
          _chessController.loadFen(data['fen']);
          if (data['lastMoveBy'] != "system") _playMoveSound();
        }
        
        Timestamp? updatedAt = data['updatedAt'] as Timestamp?;
        if (updatedAt != null) {
          int elapsed = DateTime.now().difference(updatedAt.toDate()).inSeconds;
          _secondsRemaining = maxTime - elapsed;
          if (_secondsRemaining < 0) _secondsRemaining = 0;
        }

        _updateTurnState();
        _checkGameStatus();
      } else {
        _syncToFirebase(isInitial: true);
      }
    });
  }

  void _checkGameStatus() {
    if (_chessController.isCheckMate()) {
      _showEndGameDialog("CHIẾU TƯỚNG!", "Trận đấu đã kết thúc.");
    } else if (_chessController.isDraw() || _chessController.isStaleMate()) {
      _showEndGameDialog("HÒA CỜ!", "Không ai giành chiến thắng.");
    }
  }

  Future<void> _resign() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Đầu hàng?"),
        content: const Text("Bạn chắc chắn muốn nhận thua ván này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("HỦY")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("ĐẦU HÀNG", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _firestore.collection('chess_games').doc(widget.roomId).update({
        'status': 'resigned',
        'winner': widget.opponentName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showEndGameDialog(String title, String sub) {
    if (_isGameOver) return;
    setState(() => _isGameOver = true);
    _timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        content: Text(sub, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text("VÁN MỚI", style: TextStyle(color: Colors.orangeAccent)),
          ),
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("THOÁT", style: TextStyle(color: Colors.white38))),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _isGameOver = false;
      _secondsRemaining = maxTime;
      validMovesSquares.clear();
      selectedSquare = null;
    });
    _chessController.resetBoard();
    _syncToFirebase(isInitial: true);
  }

  void _updateTurnState() {
    String fen = _chessController.getFen();
    bool isWhiteTurn = fen.contains(" w ");
    myTurn = (isWhiteTurn && isWhite) || (!isWhiteTurn && !isWhite);
    if (myTurn && !_isGameOver) {
      _startCountdown();
    } else {
      _timer?.cancel();
    }
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
          if (!_isGameOver) {
             _showEndGameDialog("HẾT GIỜ!", "Bạn đã hết thời gian suy nghĩ.");
          }
        }
      });
    });
  }

  void _syncToFirebase({bool isInitial = false}) {
    if (!isInitial) _playMoveSound();

    _firestore.collection('chess_games').doc(widget.roomId).set({
      'fen': _chessController.getFen(),
      'lastMoveBy': isInitial ? "system" : widget.currentUserId,
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'playing',
      'winner': '',
    });
    
    setState(() {
      validMovesSquares.clear();
      selectedSquare = null;
    });
  }

  void _onSquareTap(String square) {
    if (!myTurn || _isGameOver) return;

    final game = chess_lib.Chess.fromFEN(_chessController.getFen());
    
    if (selectedSquare != null && validMovesSquares.contains(square)) {
      bool moved = game.move({'from': selectedSquare!, 'to': square, 'promotion': 'q'});
      if (moved) {
        _chessController.loadFen(game.fen);
        _syncToFirebase();
      }
      return;
    }

    final piece = game.get(square);
    if (piece != null) {
      bool isMyPiece = (piece.color == chess_lib.Color.WHITE && isWhite) || 
                       (piece.color == chess_lib.Color.BLACK && !isWhite);
      
      if (isMyPiece) {
        final moves = game.generate_moves({'square': square});
        setState(() {
          selectedSquare = square;
          validMovesSquares = moves.map((m) => m.toAlgebraic).toList();
        });
      } else {
        setState(() {
          selectedSquare = null;
          validMovesSquares.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double boardSize = MediaQuery.of(context).size.width - 40;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text("Cờ Vua Trực Tuyến", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          if (!_isGameOver) IconButton(icon: const Icon(Icons.flag_outlined, color: Colors.redAccent), onPressed: _resign),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _resetGame),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildPlayerInfo(widget.opponentName, !myTurn, !isWhite),
          const Spacer(),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF262626),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ChessBoard(
                  controller: _chessController,
                  onMove: () => _syncToFirebase(),
                  boardColor: BoardColor.brown,
                  boardOrientation: isWhite ? PlayerColor.white : PlayerColor.black,
                  size: boardSize,
                  enableUserMoves: myTurn && !_isGameOver,
                ),
              ),
<<<<<<< Updated upstream
              Container(
=======
              // LỚP PHỦ TRONG SUỐT ĐỂ NHẬN DIỆN CÚ NHẤN VÀ VẼ CHẤM GỢI Ý
              SizedBox(
>>>>>>> Stashed changes
                width: boardSize,
                height: boardSize,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                  itemCount: 64,
                  itemBuilder: (context, index) {
                    int row = index ~/ 8;
                    int col = index % 8;
                    String file = isWhite ? String.fromCharCode(97 + col) : String.fromCharCode(104 - col);
                    int rank = isWhite ? (8 - row) : (row + 1);
                    String square = "$file$rank";
                    bool isHint = validMovesSquares.contains(square);
                    bool isSelected = selectedSquare == square;
                    return GestureDetector(
                      onTap: () => _onSquareTap(square),
                      child: Container(
<<<<<<< Updated upstream
                        decoration: BoxDecoration(color: isSelected ? Colors.yellow.withOpacity(0.3) : Colors.transparent),
                        child: Center(child: isHint ? Container(width: 15, height: 15, decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle)) : const SizedBox()),
=======
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.yellow.withValues(alpha: 0.3) : Colors.transparent,
                        ),
                        child: Center(
                          child: isHint 
                            ? Container(
                                width: 15, height: 15,
                                decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                              ) 
                            : const SizedBox(),
                        ),
>>>>>>> Stashed changes
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildPlayerInfo("Bạn (${isWhite ? 'Trắng' : 'Đen'})", myTurn, isWhite),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(String name, bool active, bool isWhitePlayer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? Colors.orangeAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: active ? Colors.orangeAccent : Colors.transparent, width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isWhitePlayer ? Colors.white : Colors.black,
              radius: 18,
              child: Icon(Icons.person, color: isWhitePlayer ? Colors.black : Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: TextStyle(color: active ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 16))),
            Text(
              "${(_secondsRemaining ~/ 60)}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}",
              style: TextStyle(color: active ? Colors.orangeAccent : Colors.white38, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}
