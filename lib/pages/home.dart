import 'package:flutter/material.dart';

// 主頁面
class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0.0,
          title: const TabBar(
            labelPadding: EdgeInsets.zero,
            tabs: <Widget>[
              Tab(text: "Home"),
              Tab(text: "Others"),
            ],
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            )
          ],
        ),
        body: TabBarView(
          children: <Widget>[
            HomePage(),
            const Text("Others"),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                child: Text("User Name"),
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                ),
              ),
              ListTile(
                title: const Text("Sign out"),
                onTap: () {
                  Navigator.pushReplacementNamed(context, "/login");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 首頁
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView(
        children: <Widget>[
          Container(
            child: Divider(
              height: 8.0,
              color: Colors.grey[200],
            ),
            color: Colors.grey[200],
          ),
          ListTile(
            dense: true,
            title: const Text("HOME"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(
            height: 0.0,
          ),
          ListTile(
            title: const Text("Home1"),
            subtitle: const Text("2 hours ago"),
            onTap: () {},
          ),
          const Divider(
            height: 0.0,
          ),
          ListTile(
            title: const Text("Home2"),
            subtitle: const Text("1 hour ago"),
            onTap: () {},
          ),
          const Divider(
            height: 0.0,
          ),
          Container(
            child: Divider(
              height: 8.0,
              color: Colors.grey[200],
            ),
            color: Colors.grey[200],
          ),
          ListTile(
            dense: true,
            title: const Text("ITEMS"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(
            height: 0.0,
          ),
          ListTile(
            title: const Text("Item1"),
            subtitle: const Text("2 hours ago"),
            onTap: () {},
          ),
          const Divider(
            height: 0.0,
          ),
          ListTile(
            title: const Text("Item2"),
            subtitle: const Text("1 hour ago"),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
