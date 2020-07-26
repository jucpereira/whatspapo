import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatspapo/telas/AbaAmigos.dart';
import 'package:whatspapo/telas/AbaConversas.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  TabController _tabController;
  List<String> itemMenu = [
    'Configurações',
    'Deslogar'
  ];
  String _emailUsuario = '';

  Future _recuperarDadosUsuaio() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await auth.currentUser();

    setState(() {
      _emailUsuario = usuarioLogado.email;
    });
  }

  Future _verificarUsuLogado() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    // auth.signOut();

    FirebaseUser usuarioLogado = await auth.currentUser();

    if (usuarioLogado == null) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void initState() {
    super.initState();

    _verificarUsuLogado();
    _recuperarDadosUsuaio();
    _tabController = TabController(
        length: 2,
        vsync: this
    );
  }

  _menuItem(String itemEscolhido) {

    switch(itemEscolhido){
      case 'Configurações':
        Navigator.pushNamed(context, '/configuracoes');
        break;
      case 'Deslogar':
        _deslogarUsuario();
        break;
    }
print('item escolhido: ' + itemEscolhido);
  }
  _deslogarUsuario()async{
    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WhatsPapo'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _menuItem,
            itemBuilder: (context) {
              return itemMenu.map( (String item){
                return PopupMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList();

            },
          )
        ],
        bottom: TabBar(
          indicatorWeight: 4,
          labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: <Widget>[
            Tab(text: 'Conversas'),
            Tab(text: 'Amigos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          AbaConversas(),
          AbaAmigos(),
        ],
      ),
    );
  }
}
