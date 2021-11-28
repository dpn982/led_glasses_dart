import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  Color color1 = Colors.deepOrange;
  Color color2 = Colors.deepPurple;
  String textToSend = "";
  late BluetoothService uartService;
  late BluetoothCharacteristic tx;
  late BluetoothCharacteristic rx;
  final double _iconSize = 24;
  final double _borderRadius = 30;
  final double _blurRadius = 5;
  final int _portraitCrossAxisCount = 4;
  final int _landscapeCrossAxisCount = 5;
  bool isConnected = false;
  final String _uartServiceUUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  final String _uartTxCharacteristicUUID =
      "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  final String _uartRxCharacteristicUUID =
      "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

  static const List<Color> colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
    Color.fromARGB(100,255,0,0),
    Color.fromARGB(100,0,255,0),
    Color.fromARGB(100,0,0,255),
  ];

  void changeColor1(Color color) => setState(() => color1 = color);

  void changeColor2(Color color) => setState(() => color2 = color);

  Widget pickerItemBuilder(
      Color color, bool isCurrentColor, void Function() changeColor) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        color: color,
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.8),
              offset: const Offset(1, 2),
              blurRadius: _blurRadius)
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: changeColor,
          borderRadius: BorderRadius.circular(_borderRadius),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isCurrentColor ? 1 : 0,
            child: Icon(
              Icons.done,
              size: _iconSize,
              color: useWhiteForeground(color) ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget pickerLayoutBuilder(
      BuildContext context, List<Color> colors, PickerItem child) {
    Orientation orientation = MediaQuery.of(context).orientation;

    return SizedBox(
      width: 300,
      height: orientation == Orientation.portrait ? 360 : 240,
      child: GridView.count(
        crossAxisCount: orientation == Orientation.portrait
            ? _portraitCrossAxisCount
            : _landscapeCrossAxisCount,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        children: [for (Color color in colors) child(color)],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    connect();
  }

  List<int> appendCrc(List<int> data) {
    int checksum = 0;
    for (int aData in data) {
      checksum += aData;
    }
    checksum = (~checksum); // Invert

    data.add(checksum);
    return data;
  }

  Future<void> send() async {
    if (isConnected) {
      await tx.write(formatColorAsText(1, color1));
      await tx.write(formatColorAsText(2, color2));
      await tx.write(_textToListInt('TEXT=$textToSend'));
      await tx.write(_textToListInt('SHOW'));
    }
  }

  List<int> formatColorAsText(int n, Color c) {
    List<int> colorValue = [
      n,
      c.red,
      c.green,
      c.blue
    ];

    String result = 'COLOR=${colorValue.join(",")}';
    return _textToListInt(result);
  }

  List<int> _textToListInt(String text) {
    List<int> outList = [];

    for (int i = 0; i < text.length; i++) {
      outList.add(text.codeUnitAt(i));
    }

    return outList;
  }

  List<int> _formatColor(Color c) {
    List<int> result = [
      '!'.codeUnitAt(0),
      'C'.codeUnitAt(0),
      c.red,
      c.green,
      c.blue
    ];

    result = appendCrc(result);

    print("Result" + result.toString());
    return result;
  }

  void connect() {
    widget.device.connect().then((value) {
      discoverBluetoothServices();
      isConnected = true;
    });
  }

  void disconnect() {
    widget.device.disconnect().then((value) {
      isConnected = false;
    });
  }

  Future<Null> discoverBluetoothServices() async {
    widget.device.discoverServices().then((value) {
      for (var service in value) {
        if (service.uuid.toString() == _uartServiceUUID) {
          uartService = service;
        }
      }

      for (var c in uartService.characteristics) {
        if (c.uuid.toString() == _uartTxCharacteristicUUID) {
          tx = c;
        } else if (c.uuid.toString() == _uartRxCharacteristicUUID) {
          rx = c;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: widget.device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback? onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => connect();
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0.0,
                    primary: Colors.black,
                    textStyle: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onPressed: onPressed,
                  child: Text(text));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            ExpansionTile(
              title: const Text("Color 1"),
              leading: Container(
                margin: const EdgeInsets.all(10.0),
                color: color1,
                width: 48.0,
                height: 48.0,
              ),
              children: <Widget>[
                BlockPicker(
                  pickerColor: color1,
                  onColorChanged: changeColor1,
                  availableColors: colors,
                  layoutBuilder: pickerLayoutBuilder,
                  itemBuilder: pickerItemBuilder,
                ),
              ],
            ),
            ExpansionTile(
              title: const Text("Color 2"),
              leading: Container(
                margin: const EdgeInsets.all(10.0),
                color: color2,
                width: 48.0,
                height: 48.0,
              ),
              children: <Widget>[
                BlockPicker(
                  pickerColor: color2,
                  onColorChanged: changeColor2,
                  availableColors: colors,
                  layoutBuilder: pickerLayoutBuilder,
                  itemBuilder: pickerItemBuilder,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                initialValue: textToSend,
                keyboardType: TextInputType.multiline,
                maxLines: 10,
                decoration: const InputDecoration(
                  prefixText: "",
                  labelText: "",
                  labelStyle: TextStyle(
                    fontSize: 18.0,
                    color: Colors.black,
                  ),
                  fillColor: Colors.white,
                  focusColor: Colors.white,
                  filled: false,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1.0,
                      color: Colors.black,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1.0,
                      color: Colors.black,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1.0,
                      color: Colors.black,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    textToSend = value;
                  });
                },
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () => send(),
                  style: ElevatedButton.styleFrom(
                    elevation: 0.0,
                  ),
                  child: Text("Send"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
