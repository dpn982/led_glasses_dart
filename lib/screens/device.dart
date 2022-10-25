import 'dart:async';
import 'dart:core';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;
  final bool isConnected;

  const DeviceScreen(
      {Key? key, required this.device, required this.isConnected})
      : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  Color color1 = Colors.black;
  Color color2 = Colors.black;
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
  String? selectedType;

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
    Color.fromARGB(100, 255, 0, 0),
    Color.fromARGB(100, 0, 255, 0),
    Color.fromARGB(100, 0, 0, 255),
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

    if (!widget.isConnected) {
      connect();
    } else {
      discoverBluetoothServices().then((value) {
        setState(() {
          isConnected = true;
        });
      });
    }
  }

  // @override
  // void dispose() {
  //   super.dispose();
  //   disconnect();
  // }

  void showSnackBar(BuildContext context, String message, Color c) {
    var snackBar = SnackBar(
      content: Text(message),
      backgroundColor: c,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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

  Future<void> send(BuildContext context) async {
    if (isConnected) {
      final dialogContextCompleter = Completer<BuildContext>();

      try {
        //await _setMTU(512);
        //await widget.device.requestMtu(512);
        //await Future.delayed(const Duration(seconds: 10));

        showDialog(
          builder: (BuildContext context) {
            if (!dialogContextCompleter.isCompleted) {
              dialogContextCompleter.complete(context);
            }
            return const SimpleDialog(
              title: Center(
                child: Text("Sending To Device"),
              ),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: null,
                      strokeWidth: 10.0,
                    ),
                  ),
                ),
              ],
            );
          },
          context: context,
        );

        var commandText = "SHOW";

        developer.log("Sending Payload", name: "Device Send");
        await Future.delayed(const Duration(seconds: 1), () async {
          await tx.write(_textToListInt('TEXT=$textToSend'));
        });
        await Future.delayed(const Duration(seconds: 1), () async {
          await tx.write(formatColorsAsText(1, color1));
        });
        await Future.delayed(const Duration(seconds: 1), () async {
          await tx.write(formatColorsAsText(2, color2));
        });
        await Future.delayed(const Duration(seconds: 1), () async {
          await tx.write(_textToListInt(commandText));
        });
        showSnackBar(context, "Success", Colors.green);
      } catch (exception, stacktrace) {
        showSnackBar(context, 'Error Sending Message To Device.', Colors.red);

        developer.log(exception.toString(), name: "Device Send");
        developer.log(stacktrace.toString(), name: "Device Send");
      } finally {
        final dialogContext = await dialogContextCompleter.future;
        Navigator.pop(dialogContext);
      }
    } else {
      showSnackBar(
          context, "Not Connected Please Connect Before Sending.", Colors.red);
    }
  }

  Future<void> _setMTU(int value) async {
    final startMtu = await widget.device.mtu.first;
    await widget.device.requestMtu(
        value); // I would await this regardless, set a timeout if you are concerned

    var mtuChanged = Completer<void>();

// mtu is of type 'int'
    var mtuStreamSubscription = widget.device.mtu.listen((mtu) {
      if (mtu == value) {
        developer.log('Current MTU: $mtu', name: "Set Device MTU");
        mtuChanged.complete();
      }
    });

    await mtuChanged.future; // set timeout and catch exception
    mtuStreamSubscription.cancel();
  }

  List<int> formatColorsAsText(int number, Color c) {
    List<int> colorValue = [c.red, c.green, c.blue];

    String result = 'COLOR$number=${colorValue.join(",")}';
    developer.log(result);
    return _textToListInt(result);
  }

  List<int> _textToListInt(String text) {
    List<int> outList = [];

    for (int i = 0; i < text.length; i++) {
      outList.add(text.codeUnitAt(i));
    }

    return outList;
  }

  // List<int> _formatColor(Color c) {
  //   List<int> result = [
  //     '!'.codeUnitAt(0),
  //     'C'.codeUnitAt(0),
  //     c.red,
  //     c.green,
  //     c.blue
  //   ];
  //
  //   result = appendCrc(result);
  //
  //   developer.log("Result" + result.toString(), name: "device");
  //   return result;
  // }

  Future<void> connect() async {
    widget.device.connect().then((value) {
      discoverBluetoothServices().then((value) {
        setState(() {
          isConnected = true;
        });
      });
    });
  }

  void disconnect() {
    widget.device.disconnect().then((value) {
      setState(() {
        isConnected = false;
      });
    });
  }

  Future<void> discoverBluetoothServices() async {
    widget.device.discoverServices().then((value) {
      for (var service in value) {
        developer.log(service.uuid.toString(), name: "Discover Services");
        if (service.uuid.toString() == _uartServiceUUID) {
          uartService = service;
        }
      }

      for (var c in uartService.characteristics) {
        developer.log(c.uuid.toString(),
            name: "Discover Characteristics Services");
        if (c.uuid.toString() == _uartTxCharacteristicUUID) {
          developer.log("TX Found", name: "Discover Characteristics Services");
          tx = c;
        } else if (c.uuid.toString() == _uartRxCharacteristicUUID) {
          developer.log("RX Found", name: "Discover Characteristics Services");
          rx = c;
        }
      }
    });
  }

  Future showColorDialog(Color currentColor) {
    Color pickerColor = currentColor;
    List<Color> colorHistory = [];

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              enableAlpha: true,
              displayThumbColor: true,
              hexInputBar: true,
              colorHistory: colorHistory,
              onHistoryChanged: (List<Color> colors) => colorHistory = colors,
              onColorChanged: (value) {
                setState(() {
                  pickerColor = value;
                });
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Reset'),
              onPressed: () {
                setState(() => pickerColor = currentColor);
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.pop(context, pickerColor);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    RoundedRectangleBorder cardBorder = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
        side: const BorderSide(
          color: Colors.black,
          width: 5.0,
        ));

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
                    backgroundColor: Colors.black,
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
      body: Container(
        color: Colors.grey,
        child: ListView(
          //mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Card(
              elevation: 5.0,
              shape: cardBorder,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: const SizedBox(
                    width: 48.0,
                    height: 48.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black,
                      ),
                    ),
                  ),
                  title: const Text("Type"),
                  trailing: DropdownButton<String>(
                    hint: const Text("Select a type"),
                    value: selectedType,
                    items: <String>['A', 'B', 'C', 'D'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (selectedValue) {
                      setState(() {
                        selectedType = selectedValue;
                      });
                    },
                  ),
                ),
              ),
            ),
            Card(
              elevation: 5.0,
              shape: cardBorder,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: SizedBox(
                    width: 48.0,
                    height: 48.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color1,
                      ),
                    ),
                  ),
                  title: const Text("Color 1"),
                  trailing: ElevatedButton(
                    onPressed: () {
                      showColorDialog(color1).then((value) {
                        setState(() {
                          color1 = value;
                        });
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                    ),
                    child: const Text("Choose Color"),
                  ),
                ),
              ),
            ),
            Card(
              elevation: 5.0,
              shape: cardBorder,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: SizedBox(
                    width: 48.0,
                    height: 48.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color2,
                      ),
                    ),
                  ),
                  title: const Text("Color 2"),
                  trailing: ElevatedButton(
                    onPressed: () {
                        showColorDialog(color2).then((value) {
                          setState(() {
                            color2 = value;
                          });
                        });
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                    ),
                    child: const Text("Choose Color"),
                  ),
                ),
              ),
            ),
            Card(
              elevation: 5.0,
              shape: cardBorder,
              child: Padding(
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
            ),
            Card(
              elevation: 5.0,
              shape: cardBorder,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          textToSend = "";
                          color1 = Colors.black;
                          color2 = Colors.black;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0.0,
                      ),
                      child: const Text("Reset"),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    ElevatedButton(
                      onPressed: () => isConnected ? send(context) : null,
                      style: isConnected
                          ? ElevatedButton.styleFrom(
                              elevation: 0.0,
                            )
                          : ElevatedButton.styleFrom(
                              elevation: 0.0,
                              backgroundColor: Colors.grey,
                              splashFactory: NoSplash.splashFactory,
                              shadowColor: Colors.transparent,
                            ),
                      child: const Text("Send"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
