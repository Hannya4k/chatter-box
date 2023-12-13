import 'package:chatterbox_firebase/helper/helper_function.dart';
import 'package:chatterbox_firebase/screens/ProfileScreen.dart';
import 'package:chatterbox_firebase/screens/SearchScreen.dart';
import 'package:chatterbox_firebase/screens/auth/LoginScreen.dart';
import 'package:chatterbox_firebase/service/auth_service.dart';
import 'package:chatterbox_firebase/service/database_service.dart';
import 'package:chatterbox_firebase/widgets/Widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "";
  String email = "";
  AuthService authService = AuthService();
  Stream? groups;
  bool _isLoading = false;
  String groupName = "";

  @override
  void initState(){
    super.initState();
    gettingUserData();
  }

  gettingUserData() async{
    await HelperFunctions.getUserEmailFromSF().then((value){
      setState((){
        email = value!;
      });
    });

    await HelperFunctions.getUserNameFromSF().then((value){
      setState((){
        userName = value!;
      });
    });

    //getting the list of snapshots in our Stream
    await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
    .getUserGroup()
    .then((snapshot){
      setState(() {
        groups = snapshot;
      });
    });
  }
  @override  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                nextScreen(context, const SearchScreen());
              },
              icon: const Icon(
                Icons.search,
              )),
        ],
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "ChatterBox",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 27),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 50),
          children: <Widget>[
            Icon(Icons.account_circle, size: 150, color: Colors.grey[700]),
            const SizedBox(height: 15),
            Text(
              userName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const Divider(height: 2),
            ListTile(
              onTap: () {},
              selectedColor: Theme.of(context).primaryColor,
              selected: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: const Icon(Icons.group),
              title: const Text(
                "Group Chats",
                style: TextStyle(color: Colors.black),
              ),
            ),
            ListTile(
              onTap: () {
                nextScreenReplace(
                    context, ProfileScreen(userName: userName, email: email));
              },
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: const Icon(Icons.group),
              title: const Text(
                "Profile",
                style: TextStyle(color: Colors.black),
              ),
            ),
            ListTile(
              onTap: () async{
                showDialog(
                  context: context, 
                  builder: (context){
                    return AlertDialog(
                      title: const Text("Logout"),
                      content: const Text("Are you sure you want to logout?"),
                      actions: [
                        IconButton(onPressed: (){
                          Navigator.pop(context);
                        }, 
                        icon: const Icon(Icons.cancel,color: Colors.red,)
                        ),
                        IconButton(onPressed: () async {
                          await authService.signOut();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context)=> const LoginScreen()), (route) => false);
                        }, 
                        icon: const Icon(Icons.done,color: Colors.green,)
                        )
                      ],
                    );
                  });
              },
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: const Icon(Icons.exit_to_app),
              title: const Text(
                "Log Out",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
      body: groupList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          popUpDialog(context);
        },
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }


  popUpDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context, 
      builder: (context){
        return StatefulBuilder(builder: ((context, setState) {
        return AlertDialog(
          title: const Text("Create a group", textAlign: TextAlign.left),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [ _isLoading == true ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor),) 
            : TextField(
              onChanged: (value){
                setState(() {
                  groupName = value;
                });
              },
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                borderRadius: BorderRadius.circular(20),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                borderRadius: BorderRadius.circular(20),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                borderRadius: BorderRadius.circular(20),
                ),
              ),
            )
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: (){
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
               onPressed: () async {
                    if (groupName != "") {
                      setState(() {
                        _isLoading = true;
                      });
                      DatabaseService(
                              uid: FirebaseAuth.instance.currentUser!.uid)
                          .createGroup(userName,
                              FirebaseAuth.instance.currentUser!.uid, groupName)
                          .whenComplete(() {
                        _isLoading = false;
                      });
                      Navigator.of(context).pop();
                      showSnackBar(context, Colors.green, "Group Created Successfully");
                    }
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor
              ), 
              child: const Text("CREATE"))
          ]
        );
        }));
      });
  }

  groupList() {
    return StreamBuilder(
      stream: groups, 
      builder: (context, AsyncSnapshot snapshot){
        //makes some check
        if(snapshot.hasData){
          if(snapshot.data['groups'] != null){
            if(snapshot.data['groups'].length != 0){
              return const Text("Hello");
            }else{
              return noGroupWidget();
            }
          }else{
            return noGroupWidget();
          }

        }else{
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor
            ),
          );
        }
      },
    );
  }

  noGroupWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              popUpDialog(context);
            },
            child: Icon(
              Icons.add_circle,
              color: Colors.grey[700],
              size: 75,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          const Text(
            "You've not joined any groups, tap on the add icon to create a group or also search from top search button.",
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}
