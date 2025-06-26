// import 'package:flutter/material.dart';
// import 'game_screen.dart';

// class StageScreen extends StatefulWidget {
//   final int level;
//   final int stage; // Tambahkan parameter stage
  
//   const StageScreen({super.key, required this.level, this.stage = 1});

//   @override
//   State<StageScreen> createState() => _StageScreenState();
// }

// class _StageScreenState extends State<StageScreen> {
//   int selectedStage = -1;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Stack(
//           children: [
//             // Tombol back
//             Positioned(
//               top: 10,
//               left: 10,
//               child: IconButton(
//                 icon: Icon(Icons.arrow_back, size: 40),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),

//             // Label Lv.1
//             Align(
//               alignment: Alignment.topCenter,
//               child: Container(
//                 margin: EdgeInsets.only(top: 10),
//                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                 decoration: BoxDecoration(
//                   border: Border.all(width: 2),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Text(
//                   'Lv. ${widget.level}',
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),

//             // Isi konten
//             Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     'STAGE ${widget.stage}', // Gunakan widget.stage
//                     style: TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.teal[900],
//                     ),
//                   ),
//                   SizedBox(height: 30),
//                   Wrap(
//                     spacing: 20,
//                     runSpacing: 20,
//                     alignment: WrapAlignment.center,
//                     children: List.generate(10, (index) {
//                       int levelNumber = index + 1;
//                       bool isSelected = selectedStage == levelNumber;

//                       return GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             selectedStage = levelNumber;
//                           });

//                           // Navigasi ke GameScreen dengan parameter stage dan level
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => GameScreen(
//                                 stage: widget.stage, // Kirim stage yang benar
//                                 level: levelNumber,   // Kirim level yang dipilih
//                               ),
//                             ),
//                           );
//                         },
//                         child: Stack(
//                           alignment: Alignment.center,
//                           children: [
//                             Container(
//                               width: 70,
//                               height: 70,
//                               decoration: BoxDecoration(
//                                 color: Colors.lightBlue[100],
//                                 shape: BoxShape.circle,
//                                 border: Border.all(
//                                   color: isSelected ? Colors.black : Colors.transparent,
//                                   width: 3,
//                                 ),
//                               ),
//                               child: Center(
//                                 child: Text(
//                                   '$levelNumber',
//                                   style: TextStyle(
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             if (isSelected)
//                               Positioned(
//                                 top: 10,
//                                 left: 10,
//                                 child: Icon(
//                                   Icons.check,
//                                   size: 28,
//                                   color: Colors.amber[700],
//                                 ),
//                               ),
//                           ],
//                         ),
//                       );
//                     }),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }