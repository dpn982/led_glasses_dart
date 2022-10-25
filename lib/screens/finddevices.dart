import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:led_glasses/screens/device.dart';
import 'package:led_glasses/screens/resulttile.dart';

class FindDevicesScreen extends StatefulWidget {
  const FindDevicesScreen({Key? key}) : super(key: key);

  @override
  FindDevicesScreenState createState() => FindDevicesScreenState();
}

class FindDevicesScreenState extends State<FindDevicesScreen> {
  @override
  void initState() {
    super.initState();
    FlutterBluePlus.instance.startScan(timeout: const Duration(seconds: 4));
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
            stream: FlutterBluePlus.instance.isScanning,
            initialData: false,
            builder: (c, snapshot) {
              if (snapshot.data!) {
                return ElevatedButton(
                  child: const Icon(
                    Icons.stop,
                    color: Colors.red,
                  ),
                  onPressed: () => FlutterBluePlus.instance.stopScan(),
                  style: ElevatedButton.styleFrom(
                    elevation: 0.0,
                  ),
                );
              } else {
                return ElevatedButton(
                  child: const Icon(
                    Icons.sync,
                    color: Colors.white,
                  ),
                  onPressed: () => FlutterBluePlus.instance
                      .startScan(timeout: const Duration(seconds: 4)),
                  style: ElevatedButton.styleFrom(
                    elevation: 0.0,
                  ),
                );
              }
            },
          ),
          ElevatedButton(
            child: const Icon(Icons.settings),
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              elevation: 0.0,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBluePlus.instance.startScan(timeout: const Duration(seconds: 4)),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              StreamBuilder<List<BluetoothDevice>>(
                stream: Stream.periodic(const Duration(seconds: 2))
                    .asyncMap((_) => FlutterBluePlus.instance.connectedDevices),
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
                                    child: const Text('OPEN'),
                                    onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) => DeviceScreen(
                                                device: d, isConnected: true))),
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
                stream: FlutterBluePlus.instance.scanResults,
                initialData: const [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map(
                        (r) => ScanResultTile(
                          result: r,
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) {
                            //r.device.connect();
                            return DeviceScreen(
                              device: r.device,
                              isConnected: false,
                            );
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
    );
  }
}
