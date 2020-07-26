import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatspapo/Home.dart';
import 'package:whatspapo/RouteGenerator.dart';
import 'package:whatspapo/model/Mensagem.dart';
import 'package:whatspapo/telas/AbaAmigos.dart';

class Configuracoes extends StatefulWidget {
  @override
  _ConfiguracoesState createState() => _ConfiguracoesState();
}

class _ConfiguracoesState extends State<Configuracoes> {
  TextEditingController _controllerNome = TextEditingController(text: '');
  File _imagem;
  String _idUsuarioLogado;
  bool _subindoImagem = false;
  String _urlRecuperada;

  Future _recuperarImagem(String origemImagem) async {
    File imagemSelecionada;
    var _picker = ImagePicker();

    switch (origemImagem) {
      case 'camera':
        var _imageCamera = await _picker.getImage(source: ImageSource.camera);
        imagemSelecionada = File(_imageCamera.path);
        break;
      case 'galeria':
        var _imageGaleria = await _picker.getImage(source: ImageSource.gallery);
        imagemSelecionada = File(_imageGaleria.path);
        break;
    }
    setState(() {
      _imagem = imagemSelecionada;
      if (_imagem != null) {
        _subindoImagem = true;
        _uploadImage();
      }
    });
  }

  Future _uploadImage() async {
    FirebaseStorage stora = FirebaseStorage.instance;
    StorageReference pastaRaiz = stora.ref();
    StorageReference arquivo =
        pastaRaiz.child('perfil').child(_idUsuarioLogado + '.jpg');

    //Upload da Imagem
    StorageUploadTask task = arquivo.putFile(_imagem);

    //Controlar progresso do upload
    task.events.listen((StorageTaskEvent storageEvent) {
      if (storageEvent.type == StorageTaskEventType.progress) {
        setState(() {
          _subindoImagem = true;
        });
      } else if (storageEvent.type == StorageTaskEventType.success) {
        setState(() {
          _subindoImagem = false;
        });
      }
    });

    task.onComplete.then((StorageTaskSnapshot snapshot) {
      _recuperarUrlImagem(snapshot);
    });
  }

  Future _recuperarUrlImagem(StorageTaskSnapshot snapshot) async {
    String url = await snapshot.ref.getDownloadURL();
    _atualizarUrlImagemFire(url);
    print('VER ' + url);
    setState(() {
      _urlRecuperada = url;
    });
  }

  _atualizarUrlImagemFire(String url) {
    Firestore db = Firestore.instance;

    Map<String, dynamic> dadosAtualizar = {'urlImagem': url};

    db
        .collection('usuarios')
        .document(_idUsuarioLogado)
        .updateData(dadosAtualizar);
  }

  _atualizarUrlNomeFire() {

    String nome = _controllerNome.text;
    Firestore db = Firestore.instance;

    Map<String, dynamic> dadosAtualizar = {'nome': nome};

    db
        .collection('usuarios')
        .document(_idUsuarioLogado)
        .updateData(dadosAtualizar);

    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Home()));
  }

  _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await auth.currentUser();
    _idUsuarioLogado = usuarioLogado.uid;

    Firestore db = Firestore.instance;
    DocumentSnapshot snapshot =
        await db.collection('usuarios').document(_idUsuarioLogado).get();

    Map<String, dynamic> dados = snapshot.data;
    _controllerNome.text = dados['nome'];

    if (dados['urlImagem'] != null) {
      setState(() {
        _urlRecuperada = dados['urlImagem'];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _recuperarDadosUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(16),
                  child: _subindoImagem
                      ? CircularProgressIndicator()
                      : Container(),
                ),
                CircleAvatar(
                    radius: 100,
                    backgroundColor: Colors.black12,
                    backgroundImage: _urlRecuperada != null
                        ? NetworkImage(_urlRecuperada)
                        : null),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    FlatButton(
                      child: Text('Câmera'),
                      onPressed: () {
                        _recuperarImagem('camera');
                      },
                    ),
                    FlatButton(
                      child: Text('Galeria'),
                      onPressed: () {
                        _recuperarImagem('galeria');
                      },
                    )
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _controllerNome,
                    autofocus: false,
                    keyboardType: TextInputType.text,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                        hintText: 'Nome',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30))),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 10),
                  child: RaisedButton(
                    child: Text(
                      'Salvar',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    color: Colors.green,
                    padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusDirectional.circular(30)),
                    onPressed: () {
                      _atualizarUrlNomeFire();

                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
