import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whatspapo/model/Conversa.dart';
import 'package:whatspapo/model/Mensagem.dart';
import 'package:whatspapo/model/Usuario.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';

class Mansagens extends StatefulWidget {
  Usuario amigos;

  Mansagens(this.amigos);

  @override
  _MansagensState createState() => _MansagensState();
}

class _MansagensState extends State<Mansagens> {


  File _imagem;
  File imagemSelecionada;
  String _idUsuarioLogado;
  String _idUsuarioDestinatario;
  Firestore db = Firestore.instance;
  bool _subindoImagem = false;

  List<String> listaMensagens = [];

  TextEditingController _controllerMensagem = TextEditingController();

  final _controller = StreamController<QuerySnapshot>.broadcast();
  ScrollController _scrollController = ScrollController();

  _enviarMensagem() {
    String textoMensagem = _controllerMensagem.text;
    if (textoMensagem.isNotEmpty) {

      Mensagem mensagem = Mensagem();
      mensagem.idUsuario = _idUsuarioLogado;
      mensagem.mensagem = textoMensagem;
      mensagem.urlImgem = '';
      mensagem.data = Timestamp.now().toString();
      mensagem.tipo = 'texto';

      _salvarMensagem(_idUsuarioLogado, _idUsuarioDestinatario, mensagem);

      _salvarMensagem(_idUsuarioDestinatario, _idUsuarioLogado, mensagem);

      _salvarConvera(mensagem);
    }
  }

  _salvarConvera (Mensagem msg){

    Conversa cRemetente = Conversa();
    cRemetente.idRemetente = _idUsuarioLogado;
    cRemetente.idDestinatario = _idUsuarioDestinatario;
    cRemetente.mensagem = msg.mensagem;
    cRemetente.nome = widget.amigos.nome;
    cRemetente.caminhoFoto = widget.amigos.urlImagem;
    cRemetente.tipoMensagem = msg.tipo;
    cRemetente.salvar();

    Conversa cDestinatario = Conversa();
    cDestinatario.idRemetente = _idUsuarioDestinatario ;
    cDestinatario.idDestinatario = _idUsuarioLogado;
    cDestinatario.mensagem = msg.mensagem;
    cDestinatario.nome = widget.amigos.nome;
    cDestinatario.caminhoFoto = widget.amigos.urlImagem;
    cDestinatario.tipoMensagem = msg.tipo;
    cDestinatario.salvar();

  }

  _salvarMensagem(
      String idRemetente, String idDestinatario, Mensagem msg) async {
    await db
        .collection('mensagens')
        .document(idRemetente)
        .collection(idDestinatario)
        .add(msg.toMap());

    _controllerMensagem.clear();
  }

  _enviarFoto(String origemImagem) async {

    var _picker = ImagePicker();

    _subindoImagem = true;

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
    _uploadImage();
  }

  Future _uploadImage() async {

    String _nomeImagem = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
    FirebaseStorage stora = FirebaseStorage.instance;
    StorageReference pastaRaiz = stora.ref();
    StorageReference arquivo =
    pastaRaiz
        .child('mensagens')
        .child(_idUsuarioLogado)
        .child(_nomeImagem);

    //Upload da Imagem
    StorageUploadTask task = arquivo.putFile(imagemSelecionada);

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

    Mensagem mensagem = Mensagem();
    mensagem.idUsuario = _idUsuarioLogado;
    mensagem.mensagem = '';
    mensagem.urlImgem = url;
    mensagem.data = Timestamp.now().toString();
    mensagem.tipo = 'imagem';

    _salvarMensagem(_idUsuarioLogado, _idUsuarioDestinatario, mensagem);

    _salvarMensagem(_idUsuarioDestinatario, _idUsuarioLogado, mensagem);
  }

  _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await auth.currentUser();
    _idUsuarioLogado = usuarioLogado.uid;
    _idUsuarioDestinatario = widget.amigos.idUsuario;

    _adcListenerMsn();
  }

  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  void startFirebaseListeners(){
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print('Mensagem: $message');
      },
        onResume: (Map<String, dynamic> message) async {
          print('Resume: $message');
        },
      onLaunch: (Map<String, dynamic> message) async {
        print('Launch: $message');
      },
    );
    _firebaseMessaging.getToken().then(
        (token){
          print('Token' + token);
        }
    );
  }

  Stream<QuerySnapshot> _adcListenerMsn() {
    final stream = db
        .collection('mensagens')
        .document(_idUsuarioLogado)
        .collection(_idUsuarioDestinatario)
        .orderBy('data', descending: false)
        .snapshots();

    stream.listen((dados) {
      _controller.add(dados);
      Timer(Duration(milliseconds: 50), (){
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _recuperarDadosUsuario();
    this.startFirebaseListeners();
  }


  Future<void> _escolhaFoto(BuildContext context) {
    return  showDialog(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              CupertinoActionSheet (
                actions: <Widget>[
                  CupertinoActionSheetAction(
                    child: Icon( Icons.camera_alt),
                    onPressed: (){
                      _enviarFoto('camera');
                    },
                    isDestructiveAction: false,
                  ),
                  CupertinoActionSheetAction(
                    child: Text ('Galeria'),
                    onPressed: (){
                      _enviarFoto('galeria');
                    },
                    isDestructiveAction: false,
                  )
                ],
                cancelButton: CupertinoActionSheetAction(
                  child: Text('Cancelar'),
                  onPressed: (){

                  },
                ),
              )
            ],
          )

            /*AlertDialog(
            title: Text('Escolha uma opção'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  GestureDetector(
                    child: Text('Galeria'),
                    onTap: () {
                      _enviarFoto('galeria');
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.all(15),
                  ),
                  GestureDetector(
                    child: Text('Camera'),
                    onTap: () {
                      _enviarFoto('camera');
                    },
                  ),
                ],
              ),
            ),
          )*/;
        });
  }

  @override
  Widget build(BuildContext context) {
    var _caixaMensagem = Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: TextField(
                controller: _controllerMensagem,
                autofocus: false,
                keyboardType: TextInputType.text,
                style: TextStyle(
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                    prefixIcon: IconButton(
                      icon: Icon(Icons.camera_alt),
                      onPressed: (){
                        _escolhaFoto(context);
                      }
                    ),
                    contentPadding: EdgeInsets.fromLTRB(32, 8, 32, 8),
                    hintText: 'Digite uma mensagem...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30))),
              ),
            ),
          ),
          FloatingActionButton(
            backgroundColor: Colors.black,
            child: Icon(
              Icons.send,
              color: Colors.white,
            ),
            mini: true,
            onPressed: _enviarMensagem,
          )
        ],
      ),
    );

    var stream = StreamBuilder(
      stream: _controller.stream,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(
              child: Column(
                children: <Widget>[
                  Text('Carregando mensagens...'),
                  CircularProgressIndicator()
                ],
              ),
            );
            break;
          case ConnectionState.active:
          case ConnectionState.done:
            QuerySnapshot querySnapshot = snapshot.data;

            if (snapshot.hasError) {
              return Expanded(
                child: Text('Erro ao carregar dados...'),
              );
            } else {
              return Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                    itemCount: querySnapshot.documents.length,
                    itemBuilder: (context, indice) {
                      List<DocumentSnapshot> mensagens =
                          querySnapshot.documents.toList();

                      DocumentSnapshot item = mensagens[indice];

                      double larguraContainer =
                          MediaQuery.of(context).size.width * 0.8;


                      Alignment alinhamento = Alignment.centerRight;
                      Color cor = Color(0xffF7F2E0);
                      if (_idUsuarioLogado != item['idUsuario']) {
                        alinhamento = Alignment.centerLeft;
                        cor = Colors.white;
                      }

                      return Align(
                        alignment: alinhamento,
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: Container(
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: cor,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8))),
                            child:
                            item ['tipo'] == 'texto'
                            ? Text(item['mensagem'], style: TextStyle(fontSize: 18),)
                                : Image.network(item['urlImagem']),
                          ),
                        ),
                      );
                    }),
              );
            }
            break;
        }
      },
    );

   /*var listView = Expanded(
      child: ListView.builder(
          itemCount: listaMensagens.length,
          itemBuilder: (context, indice) {
            Alignment alinhamento = Alignment.centerRight;
            Color cor = Color(0xffF7F2E0);
            if (indice % 2 == 0) {
              alinhamento = Alignment.centerLeft;
              cor = Colors.white;
            }

            return Align(
              alignment: alinhamento,
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: cor,
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  child: Text(
                    listaMensagens[indice],
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            );
          }),
    );*/

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            CircleAvatar(
                maxRadius: 20,
                backgroundColor: Colors.grey,
                backgroundImage: widget.amigos.urlImagem != null
                    ? NetworkImage(widget.amigos.urlImagem)
                    : null),
            Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text(widget.amigos.nome),
            )
          ],
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage(
                  'image/fundo.jpg',
                ),
                fit: BoxFit.cover)),
        child: SafeArea(
          child: Container(
            padding: EdgeInsets.all(8),
            child: Column(
              children: <Widget>[
                stream,
                _caixaMensagem,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
