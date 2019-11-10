// TODO: Put public facing types in this file.

import 'dart:io';
import 'dart:convert';
import 'package:sevr/src/serv_content_types/serv_content_types.dart';
import 'package:sevr/src/serv_request_response_wrapper/serv_request_wrapper.dart';
import 'package:sevr/src/serv_router/serv_router.dart';

class Sevr {
  String messageReturn = '';
  static final Sevr _serv = Sevr._internal();
  final Router router = Router();

  //Exposes a singleton Instance of the class through out its use
  factory Sevr() {
    return _serv;
  }

  Sevr._internal();

  //listens for connection on the specified port
  listen(int port,
      {Function callback,
      SecurityContext context,
      String messageReturn}) async {
    this.messageReturn = messageReturn;
    if (callback != null) {
      callback();
    }
    HttpServer server;
    if (context == null) {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    } else {
      server = await HttpServer.bindSecure(
          InternetAddress.loopbackIPv4, port, context);
    }

    await for (var request in server) {
      //calls the class as a function to handle incoming requests: calling _serv(request) runs the call method in the Serv singleton instance class
      _serv(request);
    }
  }

  call(HttpRequest request) async {
    print(request.headers.contentType);
    ServRequest req = ServRequest(request);
    ServResponse res = ServResponse(request);
      request.listen((onData)async{
        Map<String,dynamic> jsonData = {};
        switch (ServContentType(req.headers.contentType.toString())) {
          case ServContentTypeEnum.ApplicationJson:
            String s = String.fromCharCodes(onData);
            jsonData.addAll(json.decode(s))  ;
            req.body = jsonData;
            break;
        
          default:
            //Todo handle other content types
            print(req.headers.contentType.toString());
        }
      },onDone: (){
        switch (request.method) {
          case 'GET':
            _handleGet(req,res);
            break;
          default:
        }
      });
    
  }

  void _handleGet(ServRequest req, ServResponse res) async {
  List<Function(ServRequest, ServResponse)> selectedCallbacks = router.gets.containsKey(req.path) ||  router.gets.containsKey('${req.path}/')? router.gets[req.path]:null;
    if (selectedCallbacks!=null && selectedCallbacks.isNotEmpty) {
     for(var func in selectedCallbacks){
          var result = await func(req,res);
          print(result.runtimeType);
          if(result is ServResponse){
            break;
          }
      }
    } else {
      res.status(HttpStatus.notFound).json({'error':'method not found'});
    }
  }

  get(String route,List<Function(ServRequest req,ServResponse res)> callbacks){
    this.router.gets[route] = callbacks;

       }
  void _handlePost(){

  }

  void _handleDelete(){

  }

  void _handlePut(){

  }

  void _handlePatch(){

  }


}
