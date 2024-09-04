import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weather_app/core/parameter/parameter.dart';
import 'package:weather_app/core/resource/resource.dart';
import 'package:weather_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:weather_app/features/get_weather/domain/entities/get_coordinates_entity.dart';
import 'package:weather_app/features/get_weather/presentation/pages/get_coordinates.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  Future<void> _refreshWeather(BuildContext context) async {
    // Retrieve the latest state to get the latitude, longitude, and city name
    final state = context.read<DashboardBloc>().state;

    if (state is DashboardLoaded) {
      // Trigger the GetWeatherEvent with the stored data
      context.read<DashboardBloc>().add(
            GetWeatherEvent(
              parameter: ParameterWeather(
                latitude: state.weather.latitude.toString(),
                longitude: state.weather.longitude.toString(),
              ),
              cityName: state.cityName,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final message = ReceivePort();
          try {
            await Isolate.spawn(complexTask3,
                (iteration: 1000000000, sendPort: message.sendPort),
                errorsAreFatal: true,
                onError: message.sendPort,
                onExit: message.sendPort);
          } on Object {
            message.close();
          }
          final data = await message.first;
          if (data == null) {
            debugPrint("data is null");
          } else if (data is List) {
            // if the response is a list, this means an uncaught error occurred
            final errorAsString = data[0];
            final stackTraceAsString = data[1];
            debugPrint(
                "An uncaught error occurred: $errorAsString\n$stackTraceAsString");
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(data.toString()),
                ),
              );
            }
          }

          final CoordinateEntity result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GetCoordinatesPage(),
            ),
          );
          if (context.mounted) {
            context.read<DashboardBloc>().add(
                  GetWeatherEvent(
                      parameter: ParameterWeather(
                        latitude: result.latitude.toString(),
                        longitude: result.longitude.toString(),
                      ),
                      cityName: result.name.toString()),
                );
          }
        },
        child: const Icon(Icons.search),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshWeather(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading) {
                  return const SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            loadingIcon,
                            style: TextStyle(fontSize: 50),
                          ),
                          Text(
                            "Memuat Data",
                            style: TextStyle(fontSize: 30),
                          ),
                          const CircularProgressIndicator()
                        ],
                      ),
                    ),
                  );
                } else if (state is DashboardLoaded) {
                  final weatherCode =
                      state.weather.currentWeather!.weathercode!;

                  // Get the corresponding emoji and color
                  final weatherIcon = weatherCode.toEmoji;
                  final backgroundColor = weatherCode.toColor;

                  return Container(
                    color: backgroundColor,
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weatherIcon,
                          style: const TextStyle(fontSize: 50),
                        ),
                        Text(
                          state.cityName,
                          style: const TextStyle(
                              fontSize: 50, fontWeight: FontWeight.w300),
                        ),
                        Text(
                          state.weather.currentWeather!.temperature.toString() +
                              state.weather.currentWeatherUnits!.temperature
                                  .toString(),
                          style: const TextStyle(
                              fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                        Text(
                            'Terakhir Diperbarui Pada ${DateTime.now().hour}:${DateTime.now().minute}'),
                      ],
                    ),
                  );
                } else if (state is DashboardError) {
                  return SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          errorIcon,
                          style: TextStyle(fontSize: 50),
                        ),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/gif/cloud.gif',
                        width: 200,
                        height: 200,
                      ),
                      const Text(
                        "Silahkan Pilih Kota!",
                        style: TextStyle(fontSize: 30),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

complexTask(SendPort sendPort) async {
  var total = 0.0;
  for (var i = 0; i < 1000000000; i++) {
    total += i;
  }
  sendPort.send(total);
}

complexTask2(Data data) async {
  var total = 0.0;
  for (var i = 0; i < data.iteration; i++) {
    total += i;
  }
  data.sendPort.send(total);
}

//using records iteration
complexTask3(({int iteration, SendPort sendPort}) data) async {
  var total = 0.0;
  for (var i = 0; i < data.iteration; i++) {
    total += i;
  }
  Isolate.exit(data.sendPort, total);
}

extension on int {
  String get toEmoji {
    switch (this) {
      case 0:
        return '☀️';
      case 1:
      case 2:
      case 3:
      case 45:
      case 48:
        return '☁️';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
      case 95:
      case 96:
      case 99:
        return '🌧️';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return '🌨️';
      default:
        return '❓';
    }
  }
}

//extension to convert weather code to background color
extension on int {
  Color get toColor {
    switch (this) {
      case 0:
        return Colors.yellow;
      case 1:
      case 2:
      case 3:
      case 45:
      case 48:
        return Colors.blueGrey;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return Colors.lightBlueAccent;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
      case 95:
      case 96:
      case 99:
        return Colors.indigoAccent;
      default:
        return Colors.cyan;
    }
  }
}

//POJO Class
class Data {
  final int iteration;
  final SendPort sendPort;

  Data({required this.iteration, required this.sendPort});
}
