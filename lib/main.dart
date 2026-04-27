import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: NumberedTicTacToe(),
    ));

class NumberedTicTacToe extends StatefulWidget {
  @override
  _NumberedTicTacToeState createState() => _NumberedTicTacToeState();
}

class _NumberedTicTacToeState extends State<NumberedTicTacToe> {
  List<String> _board = List.filled(9, "");
  bool _studentIsX = true; 
  bool _isStudentTurn = true; 
  String _winner = "";
  List<int>? _winningLine;
  String _studentName = "";
  final TextEditingController _nameController = TextEditingController();

  bool _showFlash = true;
  Timer? _flashTimer;

  final List<List<int>> _winningCombos = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6]
  ];

  void _handleTap(int index) {
    if (_board[index] != "" || _winner != "" || _studentName.isEmpty) return;

    setState(() {
      if (_isStudentTurn) {
        _board[index] = _studentIsX ? "X" : "O";
      } else {
        _board[index] = _studentIsX ? "O" : "X";
      }
      _isStudentTurn = !_isStudentTurn;
      _checkWinner();
    });
  }

  void _checkWinner() {
    for (var combo in _winningCombos) {
      if (_board[combo[0]] != "" &&
          _board[combo[0]] == _board[combo[1]] &&
          _board[combo[0]] == _board[combo[2]]) {
        _winner = _board[combo[0]];
        _winningLine = combo;
        _startFlashing();
        return;
      }
    }
    if (!_board.contains("")) {
      setState(() {
        _winner = "Draw";
        _showFlash = true; // Ensure draw popup is visible
      });
    }
  }

  void _startFlashing() {
    _flashTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() => _showFlash = !_showFlash);
    });
  }

  void _reset() {
    _flashTimer?.cancel();
    setState(() {
      _board = List.filled(9, "");
      _isStudentTurn = true; 
      _winner = "";
      _winningLine = null;
      _showFlash = true; // Reset visibility for the next game
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String studentSymbol = _studentIsX ? "X" : "O";
    
    // Logic for the popup content
    String popupMessage = "";
    bool shouldFlash = false;

    if (_winner == "Draw") {
      popupMessage = "Cat Game ☹";
      shouldFlash = false; // Stay steady
    } else if (_winner != "") {
      popupMessage = (_winner == studentSymbol) ? "$_studentName Wins!!!!" : "Mark Wins!!!!";
      shouldFlash = true; // Flash for victory
    }

    return Scaffold(
      appBar: AppBar(title: Text("Tic-Tac-Toe")),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_studentName.isEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(labelText: "Enter Student Name"),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => setState(() => _studentName = _nameController.text),
                          child: Text("Set Student"),
                        ),
                      ],
                    )
                  else ...[
                    Text("$_studentName vs. Mark",
                        style: TextStyle(fontSize: 20, color: Colors.blue[700], fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text(
                      _winner == "" 
                          ? "Current Turn: ${_isStudentTurn ? '$_studentName ($studentSymbol)' : 'Mark (${_studentIsX ? 'O' : 'X'})'}" 
                          : "Game Over",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                    ),
                    SizedBox(height: 10),
                    if (_board.every((cell) => cell == ""))
                      OutlinedButton.icon(
                        icon: Icon(Icons.swap_horiz),
                        label: Text("Set $_studentName to ${_studentIsX ? 'O' : 'X'}"),
                        onPressed: () => setState(() => _studentIsX = !_studentIsX),
                      ),
                  ],
                  SizedBox(height: 24),
                  Stack(
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: 450),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
                          ),
                          itemCount: 9,
                          itemBuilder: (context, i) {
                            bool isEmpty = _board[i] == "";
                            return Container(
                              decoration: BoxDecoration(
                                color: isEmpty ? Colors.white : Colors.blue[50],
                                border: Border.all(color: Colors.blue, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () => _handleTap(i),
                                child: Center(
                                  child: Text(
                                    isEmpty ? "${i + 1}" : _board[i],
                                    style: TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: isEmpty ? Colors.grey[400] : (_board[i] == "X" ? Colors.blue[900] : Colors.orange[800]),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_winningLine != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(painter: LinePainter(_winningLine!)),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text("Reset Board"),
                    onPressed: _reset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Unified Popup Overlay
          if (_winner != "")
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: (shouldFlash ? _showFlash : true) ? 1.0 : 0.0,
                duration: Duration(milliseconds: shouldFlash ? 200 : 0),
                child: Container(
                  color: Colors.blue.withOpacity(0.3),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue[900]!, width: 5),
                      ),
                      child: Text(
                        popupMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// (LinePainter remains the same as previous)
class LinePainter extends CustomPainter {
  final List<int> winningLine;
  LinePainter(this.winningLine);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[900]!.withOpacity(0.8)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    Offset getOffset(int index) {
      double row = (index / 3).floor().toDouble();
      double col = (index % 3).toDouble();
      return Offset((col + 0.5) * (size.width / 3), (row + 0.5) * (size.height / 3));
    }
    canvas.drawLine(getOffset(winningLine[0]), getOffset(winningLine[2]), paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}