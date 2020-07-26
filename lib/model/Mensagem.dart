class Mensagem {
  String _idUsuario;
  String _mensagem;
  String _urlImgem;
  String _tipo; //texto ou imagem
  String _data;

  Mensagem();

  Map<String, dynamic> toMap(){
    Map<String, dynamic> map = {
      'idUsuario' : this.idUsuario,
      'mensagem' : this.mensagem,
      'urlImagem' : this.urlImgem,
      'tipo' : this.tipo,
      'data' : this.data,

    };
    return map;
  }


  String get data => _data;

  set data(String value) {
    _data = value;
  }

  String get tipo => _tipo;

  set tipo(String value) {
    _tipo = value;
  }

  String get urlImgem => _urlImgem;

  set urlImgem(String value) {
    _urlImgem = value;
  }

  String get mensagem => _mensagem;

  set mensagem(String value) {
    _mensagem = value;
  }

  String get idUsuario => _idUsuario;

  set idUsuario(String value) {
    _idUsuario = value;
  }
}