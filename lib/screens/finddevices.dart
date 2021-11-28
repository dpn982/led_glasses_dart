import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:led_glasses/screens/device.dart';
import 'package:led_glasses/screens/resulttile.dart';

class FindDevicesScreen extends StatefulWidget {
  @override
  FindDevicesScreenState createState() => FindDevicesScreenState();
}

class FindDevicesScreenState extends State<FindDevicesScreen> {
  @override
  void initState() {
    FlutterBlue.instance.startScan(timeout: const Duration(seconds: 4));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.deepPurple,
        title: const Text('Find Devices'),
        actions: <Widget>[
          StreamBuilder<bool>(
            stream: FlutterBlue.instance.isScanning,
            initialData: false,
            builder: (c, snapshot) {
              if (snapshot.data!) {
                return ElevatedButton(
                  child: const Icon(Icons.stop),
                  onPressed: () => FlutterBlue.instance.stopScan(),
                  style: ElevatedButton.styleFrom(
                    elevation: 0.0,
                    primary: Colors.red,
                  ),
                );
              } else {
                return ElevatedButton(
                  child: const Icon(Icons.sync),
                  onPressed: () => FlutterBlue.instance
                      .startScan(timeout: const Duration(seconds: 4)),
                  style: ElevatedButton.styleFrom(
                    elevation: 0.0,
                    primary: Colors.deepPurple,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              StreamBuilder<List<BluetoothDevice>>(
                stream: Stream.periodic(const Duration(seconds: 2))
                    .asyncMap((_) => FlutterBlue.instance.connectedDevices),
                initialData: const [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map((d) => ListTile(
                            title: Text(d.name),
                            subtitle: Text(d.id.toString()),
                            trailing: StreamBuilder<BluetoothDeviceState>(
                              stream: d.state,
                              initialData: BluetoothDeviceState.disconnected,
                              builder: (c, snapshot) {
                                if (snapshot.data ==
                                    BluetoothDeviceState.connected) {
                                  return ElevatedButton(
                                    child: Text('OPEN'),
                                    onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                DeviceScreen(device: d))),
                                  );
                                }
                                return Text(snapshot.data.toString());
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: const [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map(
                        (r) => ScanResultTile(
                          result: r,
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) {
                            //r.device.connect();
                            return DeviceScreen(device: r.device);
                          })),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      /*   floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),*/
    );
  }
}
