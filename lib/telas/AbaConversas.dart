import 'dart:async';
//import 'dart:html';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:whatspapo/model/Conversa.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatspapo/model/Usuario.dart';

class AbaConversas extends StatefulWidget {
  @override
  _AbaConversaState createState() => _AbaConversaState();
}

class _AbaConversaState extends State<AbaConversas> {

  final _controller = StreamController<QuerySnapshot>.broadcast();
  Firestore db = Firestore.instance;
  String _idUsuarioLogado;

  @override
  void initState() {
    super.initState();

    _recuperarDadosUsuario();

      }

  Stream<QuerySnapshot> _adcListenerConversas() {
    final stream = db
        .collection('conversas')
        .document(_idUsuarioLogado)
        .collection('Ultima_Conversa')
        .snapshots();

    stream.listen((dados) {
      _controller.add(dados);
    });
  }

  _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await auth.currentUser();
    _idUsuarioLogado = usuarioLogado.uid;

    _adcListenerConversas();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.stream,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(
              child: Column(
                children: <Widget>[
                  Text('Carregando conversas'),
                  CircularProgressIndicator()
                ],
              ),
            );
            break;
          case ConnectionState.active:
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Text('Erro ao carregar dados');
            } else {
              QuerySnapshot querySnapshot = snapshot.data;
              print("quantas mensagens eu tenho? " +querySnapshot.documents.length.toString());
              if (querySnapshot.documents.length == 0) {
                return Center(
                  child: Text('Não há conversas'),
                );
              }
              return ListView.builder(
                  itemCount: querySnapshot.documents.length,
                  itemBuilder: (context, indice) {
                    List<DocumentSnapshot> conversas =
                        querySnapshot.documents.toList();

                    DocumentSnapshot item = conversas[indice];
                    String urlImagem = item['caminhoFoto'];
                    String tipo = item['tipoMensagem'];
                    String mensagem = item['mensagem'];
                    String nome = item['nome'];
                    String idDestinatario = item['idDestinatario'];

                    Usuario usuario = Usuario();
                    usuario.nome = nome;
                    usuario.urlImagem = urlImagem;
                    usuario.idUsuario = idDestinatario;

                    return ListTile(
                      onTap: (){
                        Navigator.pushNamed(
                            context,
                            '/mensagens',
                            arguments: usuario
                        );
                      },
                      contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      leading: CircleAvatar(
                        maxRadius: 30,
                        backgroundColor: Colors.grey,
                        backgroundImage:
                            urlImagem != null ? NetworkImage(urlImagem) : null,
                      ),
                      title: Text(
                        nome,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        tipo == 'texto' ? mensagem : 'Imagem',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    );
                  });
            }
        }
      },
    );
  }
}
