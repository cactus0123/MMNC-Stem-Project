import 'package:flutter/material.dart';
import 'send_page.dart'; // import the SendPage widget
//import 'receive_page.dart'; // import the ReceivePage widget

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose an option'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shadowColor: Colors.deepPurpleAccent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                minimumSize: const Size(200, 100),
              ),
              child: const Text('Send', style: TextStyle(fontSize: 30)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const MyHomePage(title: 'Send Page')),
                );
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shadowColor: Colors.deepPurpleAccent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                minimumSize: const Size(200, 100),
              ),
              child: const Text('Receive', style: TextStyle(fontSize: 30)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Placeholder()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
