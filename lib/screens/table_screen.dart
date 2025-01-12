import 'package:flutter/material.dart';
import 'package:gaster/services/csv_service.dart';

class TableScreen extends StatelessWidget {
  const TableScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<List<CSVObject>>(
          future: readCSV(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No locations found'),
              );
            }

            return ListView(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('District')),
                      DataColumn(label: Text('Latitude')),
                      DataColumn(label: Text('Longitude')),
                    ],
                    rows: snapshot.data!
                        .map((location) => DataRow(
                              cells: [
                                DataCell(Text(location.Name)),
                                DataCell(Text(location.District)),
                                DataCell(Text(location.Latitude)),
                                DataCell(Text(location.Longitude)),
                              ],
                            ))
                        .toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
