import 'dart:async';
import 'dart:html' as html; 
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: NumberedTicTacToe(),
      debugShowCheckedModeBanner: false,
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
  String _teacherName = "Mark"; 
  
  final TextEditingController _studentController = TextEditingController();
  final TextEditingController _teacherController = TextEditingController();

  bool _showFlash = true;
  Timer? _flashTimer;

  final List<List<int>> _winningCombos = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6]
  ];

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final uri = Uri.parse(html.window.location.href);
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _studentName = uri.queryParameters['student'] ?? "";
      _teacherName = uri.queryParameters['teacher'] ?? "";

      if (_studentName.isEmpty) {
        _studentName = prefs.getString('studentName') ?? "";
      }
      if (_teacherName.isEmpty) {
        _teacherName = prefs.getString('teacherName') ?? "Mark";
      }

      _studentController.text = _studentName;
      _teacherController.text = _teacherName;
    });
  }

  Future<void> _saveAndStart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('studentName', _studentController.text);
    await prefs.setString('teacherName', _teacherController.text);
    
    setState(() {
      _studentName = _studentController.text;
      _teacherName = _teacherController.text;
    });
  }

  Future<void> _clearNames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('studentName');
    setState(() {
      _studentName = "";
      _studentController.clear();
    });
  }

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
        _showFlash = true; 
      });
    }
  }

  void _startFlashing() {
    _flashTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
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
      _showFlash = true;
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _studentController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;
    double boardWidth = isMobile ? screenWidth * 0.9 : 450.0;

    String studentSymbol = _studentIsX ? "X" : "O";
    String teacherSymbol = _studentIsX ? "O" : "X";
    
    String popupMessage = "";
    bool shouldFlash = false;

    if (_winner == "Draw") {
      popupMessage = "Cat Game ☹";
      shouldFlash = false;
    } else if (_winner != "") {
      popupMessage = (_winner == studentSymbol) ? "$_studentName Wins!!!!" : "$_teacherName Wins!!!!";
      shouldFlash = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tic-Tac-Toe", style: TextStyle(fontSize: 28)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center( 
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Container(
                  width: boardWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_studentName.isEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Setup Session", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                            TextField(controller: _teacherController, decoration: const InputDecoration(labelText: "Teacher Name")),
                            TextField(controller: _studentController, decoration: const InputDecoration(labelText: "Student Name")),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(onPressed: _saveAndStart, child: const Text("Start Session")),
                            ),
                          ],
                        )
                      else ...[
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.center,
                          children: [
                            Text("$_studentName vs. $_teacherName",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18, color: Colors.blue[700], fontWeight: FontWeight.bold)),
                            IconButton(
                              onPressed: _clearNames,
                              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                              tooltip: "Change Names",
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _winner == "" 
                              ? "Turn: ${_isStudentTurn ? '$_studentName ($studentSymbol)' : '$_teacherName ($teacherSymbol)'}" 
                              : "Game Over",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                        ),
                        const SizedBox(height: 10),
                        if (_board.every((cell) => cell == ""))
                          OutlinedButton.icon(
                            icon: const Icon(Icons.swap_horiz),
                            label: Text("Set $_studentName to ${studentSymbol == 'X' ? 'O' : 'X'}"),
                            onPressed: () => setState(() => _studentIsX = !_studentIsX),
                          ),
                      ],
                      const SizedBox(height: 16),
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: Stack(
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
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
                                          fontSize: isMobile ? 32 : 42,
                                          fontWeight: FontWeight.bold,
                                          color: isEmpty ? Colors.grey[400] : (_board[i] == "X" ? Colors.blue[900] : Colors.orange[800]),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (_winningLine != null)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(painter: LinePainter(_winningLine!)),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text("Reset Board"),
                          onPressed: _reset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text("Brought to you by ", style: TextStyle(fontSize: 14, color: Colors.grey)),
                          InkWell(
                            onTap: () => html.window.open('https://www.phonogramuniversity.com', '_blank'),
                            child: const Text(
                              "Phonogram University",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          if (_winner != "")
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: (shouldFlash ? _showFlash : true) ? 1.0 : 0.0,
                duration: Duration(milliseconds: shouldFlash ? 200 : 0),
                child: Container(
                  color: Colors.blue.withOpacity(0.3),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue[900]!, width: 5),
                        ),
                        child: Text(
                          popupMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 32 : 48, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.blue[900]
                          ),
                        ),
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