import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Material App',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CollectionReference _products =
      FirebaseFirestore.instance.collection('products');
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // make function future for update/create/view data dynamic
  Future<void> _functionDynamic([DocumentSnapshot? documentSnapshot]) async {
    String actionText;
    if (documentSnapshot != null) {
      actionText = "Update";
      _nameController.text = documentSnapshot['name'];
      _priceController.text = documentSnapshot['price'].toString();
    } else {
      actionText = "Create";
    }

    await showModalBottomSheet(
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: actionText == 'Create'
                        ? () async {
                            final String name = _nameController.text;
                            final double? price =
                                double.tryParse(_priceController.text);
                            if (price != null) {
                              await _products
                                  .add({"name": name, "price": price});

                              _nameController.text = '';
                              _priceController.text = '';
                              // ignore: use_build_context_synchronously
                              Navigator.pop(ctx);
                            }
                          }
                        : actionText == 'Update'
                            ? () async {
                                final String name = _nameController.text;
                                final double? price =
                                    double.tryParse(_priceController.text);
                                if (price != null) {
                                  await _products
                                      .doc(documentSnapshot!.id)
                                      .update({"name": name, "price": price});

                                  _nameController.text = '';
                                  _priceController.text = '';
                                  // ignore: use_build_context_synchronously
                                  Navigator.pop(ctx);
                                }
                              }
                            : () {},
                    child: Text(actionText),
                  )
                ],
              ),
            ),
          );
        });
  }
  // end

  // make function future delete data
  Future<void> _functionDelete(String productId) async {
    await _products.doc(productId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("You have successfully delete a data"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Firebase CRUD"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _functionDynamic();
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: StreamBuilder(
        stream: _products.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          // jika function stream get data
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                    streamSnapshot.data!.docs[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(
                      documentSnapshot['name'],
                    ),
                    subtitle: Text(
                      documentSnapshot['price'].toString(),
                    ),
                    trailing: SizedBox(
                      width: 160,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => _functionDynamic(documentSnapshot),
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.remove_red_eye),
                          ),
                          IconButton(
                            onPressed: () {
                              _functionDelete(documentSnapshot.id);
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          // selain ketika get data
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
