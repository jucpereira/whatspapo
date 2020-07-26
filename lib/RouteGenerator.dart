import 'package:flutter/material.dart';
import 'package:whatspapo/Cadastro.dart';
import 'package:whatspapo/Configuracoes.dart';
import 'package:whatspapo/Home.dart';
import 'package:whatspapo/Home2.dart';
import 'package:whatspapo/Login.dart';

import 'Mensagens.dart';

class RouteGenerator {
  static Route<dynamic> generatorRoute(RouteSettings settings) {

    final args = settings.arguments;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) =>
              Login(), // usar o _ é o mesmo que usar o context, porem ocupa menos memoria
        );
      case '/login':
        return MaterialPageRoute(
          builder: (_) =>
              Login(), // usar o _ é o mesmo que usar o context, porem ocupa menos memoria
        );
      case '/cadastro':
        return MaterialPageRoute(
          builder: (_) =>
              Cadastro(), // usar o _ é o mesmo que usar o context, porem ocupa menos memoria
        );
      case '/home':
        return MaterialPageRoute(
          builder: (_) =>
              Home(), // usar o _ é o mesmo que usar o context, porem ocupa menos memoria
        );
      case '/configuracoes':
        return MaterialPageRoute(
          builder: (_) =>
              Configuracoes(), // usar o _ é o mesmo que usar o context, porem ocupa menos memoria
        );
      case '/mensagens':
        return MaterialPageRoute(
          builder: (_) =>
              Mansagens(args), // usar o _ é o mesmo que usar o context, porem ocupa menos memoria
        );

        defaut: _erroRota ();
    }
  }
  static Route <dynamic> _erroRota(){
    return MaterialPageRoute(
      builder: (_){
        return Scaffold (
          appBar: AppBar(
            title: Text ('tela nao encontrada'),
          ),
          body: Center(
            child: Text ('tela nao encontrada'),
          ),
        );
      }
    );
  }
}
