import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BlockBlastGamePage extends StatefulWidget {
  final String? roomId;
  final String? currentUserId;
  final String? opponentName;
  final bool isSolo;

  const BlockBlastGamePage({
    super.key,
    this.roomId,
    this.currentUserId,
    this.opponentName,
    this.isSolo = false,
  });

  @override
  State<BlockBlastGamePage> createState() => _BlockBlastGamePageState();
}

class _BlockBlastGamePageState extends State<BlockBlastGamePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey _boardKey = GlobalKey();
  
  static const int gridSize = 8;
  List<int> grid = List.filled(gridSize * gridSize, 0); 
  List<List<List<int>>> currentPieces = [[], [], []]; 
  
  int myScore = 0;
  int opponentScore = 0;
  int highScore = 0;
  bool myTurn = true;
  late bool isPlayer1;
  
  // Ghost Preview State
  int? ghostRow;
  int? ghostCol;
  int? draggingIndex;

  Timer? _timer;
  int _secondsRemaining = 90;
  static const int maxTime = 90;

  @override
  void initState() {
    super.initState();
    if (widget.isSolo) {
      isPlayer1 = true;
      myTurn = true;
      _generateNewPiecesSolo();
    } else {
      isPlayer1 = widget.currentUserId!.compareTo(widget.opponentName!) < 0;
      _listenToGame();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateNewPiecesSolo() {
    setState(() {
      currentPieces = _generateRandomShapes();
    });
    _checkGameOverSolo();
  }

  void _playFeedback(bool isBlast) {
    SystemSound.play(SystemSoundType.click);
    if (isBlast) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  void _listenToGame() {
    if (widget.isSolo) return;
    _firestore.collection('block_blast_games').doc(widget.roomId).snapshots().listen((snapshot) {
      if (!mounted) return;
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data()!;
        setState(() {
          grid = List<int>.from(data['grid'] ?? List.filled(gridSize * gridSize, 0));
          myScore = isPlayer1 ? (data['p1Score'] ?? 0) : (data['p2Score'] ?? 0);
          opponentScore = isPlayer1 ? (data['p2Score'] ?? 0) : (data['p1Score'] ?? 0);
          
          var piecesData = data['currentPieces'] as List<dynamic>?;
          if (piecesData != null && piecesData.isNotEmpty) {
            currentPieces = piecesData.map((p) => (p as List).map((row) => List<int>.from(row)).toList()).toList();
          } else {
            _forceGeneratePieces();
          }
        });

        Timestamp? updatedAt = data['updatedAt'] as Timestamp?;
        if (updatedAt != null) {
          int elapsed = DateTime.now().difference(updatedAt.toDate()).inSeconds;
          _secondsRemaining = maxTime - elapsed;
          if (_secondsRemaining < 0) _secondsRemaining = 0;
        }
        
        _updateTurnState(data['lastMoveBy']);
      } else {
        _initNewGame();
      }
    });
  }

  void _forceGeneratePieces() {
    if (myTurn && (currentPieces.isEmpty || currentPieces.every((p) => p.isEmpty))) {
      _syncToFirebase(newPieces: _generateRandomShapes());
    }
  }

  void _initNewGame() {
    _syncToFirebase(
      initialGrid: List.filled(gridSize * gridSize, 0),
      newPieces: _generateRandomShapes(),
      isInitial: true,
    );
  }

  List<List<List<int>>> _generateRandomShapes() {
    List<List<List<int>>> allShapes = [
      [[1]], [[1, 1]], [[1, 1, 1]], [[1, 1], [1, 1]], 
      [[1], [1]], [[1], [1], [1]], [[1, 1, 1, 1]], 
      [[1, 1], [1, 0]], [[1, 1, 1], [0, 1, 0]], [[1, 1, 1], [1, 0, 0]]
    ];
    Random r = Random();
    return List.generate(3, (_) => allShapes[r.nextInt(allShapes.length)]);
  }

  void _updateTurnState(String? lastMoveBy) {
    myTurn = (lastMoveBy == null || lastMoveBy == "system") ? isPlayer1 : lastMoveBy != widget.currentUserId;
    _startCountdown();
  }

  void _startCountdown() {
    if (widget.isSolo) return;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) _secondsRemaining--;
        else if (myTurn) _syncToFirebase(newPieces: _generateRandomShapes()); 
      });
    });
  }

  void _onDragUpdate(int pieceIndex, Offset globalPos) {
    if (!myTurn) return;
    final RenderBox? boardBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (boardBox == null) return;

    final Offset boardOrigin = boardBox.localToGlobal(Offset.zero);
    final double cellSize = boardBox.size.width / gridSize;

    // Tính toán ô dự kiến (snapping)
    int col = ((globalPos.dx - boardOrigin.dx) / cellSize).round();
    int row = ((globalPos.dy - boardOrigin.dy) / cellSize).round();

    if (_canPlace(currentPieces[pieceIndex], row, col)) {
      setState(() {
        ghostRow = row;
        ghostCol = col;
        draggingIndex = pieceIndex;
      });
    } else {
      setState(() {
        ghostRow = null;
        ghostCol = null;
      });
    }
  }

  void _onPiecePlaced(int pieceIndex, Offset globalPos) {
    if (!myTurn || currentPieces.length <= pieceIndex || currentPieces[pieceIndex].isEmpty) return;

    final RenderBox? boardBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (boardBox == null) return;
    final Offset boardOrigin = boardBox.localToGlobal(Offset.zero);
    final double cellSize = boardBox.size.width / gridSize;

    int col = ((globalPos.dx - boardOrigin.dx) / cellSize).round();
    int row = ((globalPos.dy - boardOrigin.dy) / cellSize).round();

    var piece = currentPieces[pieceIndex];
    if (!_canPlace(piece, row, col)) {
      setState(() { ghostRow = null; ghostCol = null; });
      return;
    }

    _playFeedback(false);

    setState(() {
      ghostRow = null; ghostCol = null;
      int colorVal = widget.isSolo ? (Random().nextInt(5) + 1) : (isPlayer1 ? 1 : 2);
      for (int r = 0; r < piece.length; r++) {
        for (int c = 0; c < piece[r].length; c++) {
          if (piece[r][c] == 1) grid[(row + r) * gridSize + (col + c)] = colorVal;
        }
      }
      currentPieces[pieceIndex] = [];
      myScore += 10;
      _checkLines();
    });

    if (widget.isSolo) {
      if (currentPieces.every((p) => p.isEmpty)) _generateNewPiecesSolo();
      else _checkGameOverSolo();
    } else {
      bool allUsed = currentPieces.every((p) => p.isEmpty);
      _syncToFirebase(newPieces: allUsed ? _generateRandomShapes() : currentPieces);
    }
  }

  bool _canPlace(List<List<int>> piece, int row, int col) {
    if (row < 0 || col < 0 || row + piece.length > gridSize || col + piece[0].length > gridSize) return false;
    for (int r = 0; r < piece.length; r++) {
      for (int c = 0; c < piece[r].length; c++) {
        if (piece[r][c] == 1 && grid[(row + r) * gridSize + (col + c)] != 0) return false;
      }
    }
    return true;
  }

  void _checkLines() {
    List<int> rows = [], cols = [];
    for (int i = 0; i < gridSize; i++) {
      bool rF = true, cF = true;
      for (int j = 0; j < gridSize; j++) {
        if (grid[i * gridSize + j] == 0) rF = false;
        if (grid[j * gridSize + i] == 0) cF = false;
      }
      if (rF) rows.add(i); if (cF) cols.add(i);
    }
    if (rows.isEmpty && cols.isEmpty) return;
    _playFeedback(true);
    for (int r in rows) for (int c = 0; c < gridSize; c++) grid[r * gridSize + c] = 0;
    for (int c in cols) for (int r = 0; r < gridSize; r++) grid[r * gridSize + c] = 0;
    myScore += (rows.length + cols.length) * 100;
    if (myScore > highScore) highScore = myScore;
  }

  void _checkGameOverSolo() {
    bool canPlaceAny = false;
    for (var piece in currentPieces) {
      if (piece.isEmpty) continue;
      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          if (_canPlace(piece, r, c)) { canPlaceAny = true; break; }
        }
        if (canPlaceAny) break;
      }
    }
    if (!canPlaceAny && currentPieces.any((p) => p.isNotEmpty)) _showGameOverSolo();
  }

  void _showGameOverSolo() {
    if (!mounted) return;
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("Hết lượt!"),
      content: Text("Điểm: $myScore"),
      actions: [TextButton(onPressed: () {
        Navigator.pop(context);
        setState(() { grid = List.filled(gridSize * gridSize, 0); myScore = 0; _generateNewPiecesSolo(); });
      }, child: const Text("Chơi lại"))],
    ));
  }

  void _syncToFirebase({List<int>? initialGrid, List<List<List<int>>>? newPieces, bool isInitial = false}) {
    if (widget.isSolo) return;
    _firestore.collection('block_blast_games').doc(widget.roomId).set({
      'grid': initialGrid ?? grid,
      'currentPieces': newPieces ?? currentPieces,
      'p1Score': isPlayer1 ? myScore : (isInitial ? 0 : opponentScore),
      'p2Score': !isPlayer1 ? myScore : (isInitial ? 0 : opponentScore),
      'lastMoveBy': isInitial ? "system" : widget.currentUserId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    double boardSize = MediaQuery.of(context).size.width - 40;
    double cellSize = boardSize / gridSize;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(widget.isSolo ? "SOLO BLAST 3D" : "BATTLE BLAST 3D", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.black45, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: DragTarget<Map>(
        onWillAcceptWithDetails: (details) => true,
        onAcceptWithDetails: (details) => _onPiecePlaced(details.data['index'], details.offset),
        onMove: (details) => _onDragUpdate(details.data['index'], details.offset),
        builder: (context, _, __) => Column(
          children: [
            const SizedBox(height: 20),
            _buildScoreBoard(),
            const Spacer(),
            Center(
              child: Container(
                key: _boardKey,
                width: boardSize, height: boardSize,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), 
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10)),
                    BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: -5),
                  ]
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridSize, crossAxisSpacing: 6, mainAxisSpacing: 6),
                  itemCount: gridSize * gridSize,
                  itemBuilder: (context, index) {
                    int r = index ~/ gridSize;
                    int c = index % gridSize;
                    int val = grid[index];
                    
                    // Logic hiển thị Ghost Preview
                    bool isGhost = false;
                    if (ghostRow != null && ghostCol != null && draggingIndex != null) {
                      var p = currentPieces[draggingIndex!];
                      int pr = r - ghostRow!;
                      int pc = c - ghostCol!;
                      if (pr >= 0 && pr < p.length && pc >= 0 && pc < p[0].length && p[pr][pc] == 1) isGhost = true;
                    }

                    Color? col;
                    if (val != 0) {
                      if (widget.isSolo) col = [Colors.blue, Colors.red, Colors.green, Colors.yellow, Colors.purple][val % 5];
                      else col = val == 1 ? Colors.cyanAccent : Colors.purpleAccent;
                    } else if (isGhost) {
                      col = Colors.white.withValues(alpha: 0.2);
                    }
                    
                    return _build3DBlock(col, isEmpty: val == 0 && !isGhost, isGhost: isGhost);
                  },
                ),
              ),
            ),
            const Spacer(),
            _buildPiecesArea(cellSize),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _build3DBlock(Color? color, {bool isEmpty = false, bool isGhost = false}) {
    if (isEmpty) return Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)));
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: isGhost ? null : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color!.withValues(alpha: 1.0), color.withValues(alpha: 0.6)]),
        color: isGhost ? color : null,
        boxShadow: isGhost ? [] : [
          BoxShadow(color: color!.withValues(alpha: 0.6), blurRadius: 8, offset: const Offset(0, 2)),
          BoxShadow(color: Colors.white.withValues(alpha: 0.4), blurRadius: 1, offset: const Offset(-1, -1)),
        ],
      ),
      child: isGhost ? null : Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), shape: BoxShape.circle))),
    );
  }

  Widget _buildScoreBoard() {
    if (widget.isSolo) {
      return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _scoreBoxSolo("SCORE", myScore, Colors.cyanAccent),
        _scoreBoxSolo("BEST", highScore, Colors.orangeAccent),
      ]);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _scoreBox(widget.opponentName!, opponentScore, !myTurn, Colors.purpleAccent),
        _scoreBox("Bạn", myScore, myTurn, Colors.cyanAccent),
      ]),
    );
  }

  Widget _scoreBoxSolo(String label, int val, Color col) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
      Text("$val", style: TextStyle(color: col, fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
    ]);
  }

  Widget _scoreBox(String name, int s, bool active, Color col) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), width: 155, padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: active ? col.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05), 
        borderRadius: BorderRadius.circular(25), 
        border: Border.all(color: active ? col : Colors.white10, width: 2),
        boxShadow: active ? [BoxShadow(color: col.withValues(alpha: 0.2), blurRadius: 15)] : [],
      ),
      child: Column(children: [
        Text(name, style: TextStyle(color: active ? Colors.white : Colors.white38, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
        Text("$s", style: TextStyle(color: col, fontSize: 32, fontWeight: FontWeight.w900)),
        if (active) Text("${_secondsRemaining}s", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildPiecesArea(double cellSize) {
    return Container(
      height: 140, padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(3, (i) {
        if (currentPieces.length <= i || currentPieces[i].isEmpty) return const SizedBox(width: 80);
        return Draggable<Map>(
          data: {'index': i, 'piece': currentPieces[i]},
          feedback: Material(color: Colors.transparent, child: _buildPieceWidget(currentPieces[i], cellSize * 0.95)),
          childWhenDragging: Opacity(opacity: 0.1, child: _buildPieceWidget(currentPieces[i], cellSize * 0.7)),
          onDragUpdate: (details) => _onDragUpdate(i, details.globalPosition),
          onDragEnd: (details) => setState(() { ghostRow = null; ghostCol = null; }),
          child: _buildPieceWidget(currentPieces[i], cellSize * 0.7),
        );
      })),
    );
  }

  Widget _buildPieceWidget(List<List<int>> p, double s) {
    return Column(mainAxisSize: MainAxisSize.min, children: p.map((row) => Row(
      mainAxisSize: MainAxisSize.min, children: row.map((cell) => Padding(
        padding: const EdgeInsets.all(1.5),
        child: SizedBox(width: s, height: s, child: cell == 1 ? _build3DBlock(widget.isSolo ? Colors.cyanAccent : (isPlayer1 ? Colors.cyanAccent : Colors.purpleAccent)) : const SizedBox()),
      )).toList(),
    )).toList());
  }
}
