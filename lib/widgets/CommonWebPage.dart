import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:jxt/utils/DataUtils.dart';
import 'package:jxt/utils/ThemeUtils.dart';

class CommonWebPage extends StatefulWidget {
  String title;
  String url;

  CommonWebPage({Key key, this.title, this.url}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new CommonWebPageState();
  }
}

class CommonWebPageState extends State<CommonWebPage> {
  final flutterWebViewPlugin = new FlutterWebviewPlugin();
  Brightness currentBrightness = Brightness.light;

  bool loading = true;
  double progress = 0.0;
  String title = "@defaultTitle_jxt";
  Widget refreshIndicator = new Container(
    width: 56.0,
    child: new CupertinoActivityIndicator()
  );


  @override
  void initState() {
    super.initState();
    DataUtils.getBrightness().then((isDark) {
      if (isDark == null) {
        DataUtils.setBrightness(false).then((whatever) {
          setState(() {
            currentBrightness = Brightness.light;
          });
        });
      } else {
        if (isDark) {
          setState(() {
            currentBrightness = Brightness.dark;
          });
        } else {
          setState(() {
            currentBrightness = Brightness.light;
          });
        }
      }
    });
    flutterWebViewPlugin.onStateChanged.listen((state) {
      if (state.type == WebViewState.finishLoad) {
        setState(() {
          loading = false;
        });
      } else if (state.type == WebViewState.startLoad) {
        setState(() {
          loading = true;
        });
      }
    });
    flutterWebViewPlugin.onProgressChanged.listen((progress) {
      setState(() {
        progress = progress;
      });
      print("Page progress: $progress");
    });
    flutterWebViewPlugin.onUrlChanged.listen((url) {
      setState(() {
        loading = false;
      });
    });
  }

  Widget progressBar() {
    if (progress == 1.0) {
      return new Container();
    } else {
      return new Container(
        height: 1.0,
        child: new LinearProgressIndicator(value: progress / 1.0)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (title == "@defaultTitle_jxt") {
      title = widget.title;
    }
    List<Widget> titleContent = [
      new Text(
        title,
        style: new TextStyle(color: ThemeUtils.currentColorTheme),
      ),
    ];
    Widget trailing = refreshIndicator;
    if (loading) {
      trailing = refreshIndicator;
    } else {
      trailing = new Container(
          width: 56.0,
          child: new IconButton(
              icon: new Icon(Icons.refresh),
              onPressed: () {
                flutterWebViewPlugin.reload();
              }
          )
      );
    }
    return new WebviewScaffold(
        url: widget.url,
        allowFileURLs: true,
        appBar: new AppBar(
          title: new Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: titleContent,
          ),
          actions: <Widget>[trailing],
          iconTheme: new IconThemeData(color: ThemeUtils.currentColorTheme),
          brightness: currentBrightness,
        ),
        enableAppScheme: true,
        withJavascript: true,
        withLocalStorage: true,
        withZoom: true,
      );
  }
}
