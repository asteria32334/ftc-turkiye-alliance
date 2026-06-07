import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: '    ',
    anonKey: '  ',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asteria Scouting',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const LoginPage(),
    );
  }
}

// ====================== GİRİŞ ======================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController();
  final _adminPass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asteria Scouting')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Hoş Geldin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'İsminiz', border: OutlineInputBorder())),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isNotEmpty) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ScoutingPage(userName: _nameController.text.trim())));
                }
              },
              child: const Text('Scouting Yapmaya Başla', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 40),
            const Text("Admin Girişi"),
            TextField(controller: _adminPass, decoration: const InputDecoration(labelText: 'Admin Şifresi', border: OutlineInputBorder()), obscureText: true),
            ElevatedButton(onPressed: () {
              if (_adminPass.text == "admin") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPage()));
            }, child: const Text('Admin Paneli')),
          ]),
        ),
      ),
    );
  }
}

// ====================== SCOUTING FORMU ======================
class ScoutingPage extends StatefulWidget {
  final String userName;
  const ScoutingPage({super.key, required this.userName});
  @override State<ScoutingPage> createState() => _ScoutingPageState();
}

class _ScoutingPageState extends State<ScoutingPage> {
  final _formKey = GlobalKey<FormState>();
  String matchNumber = '';
  String teamNumber = '';
  String score = '';
  String notes = '';
  String? editingId;
  List<Uint8List> selectedImages = [];

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (var image in images) {
        final bytes = await image.readAsBytes();
        setState(() => selectedImages.add(bytes));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Merhaba, ${widget.userName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => MyScoutsPage(userName: widget.userName)));
              if (result != null && result is Map<String, dynamic>) {
                setState(() {
                  editingId = result['id'].toString();
                  matchNumber = result['match_number']?.toString() ?? '';
                  teamNumber = result['team_number']?.toString() ?? '';
                  score = result['score']?.toString() ?? '';
                  notes = result['notes']?.toString() ?? '';
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(decoration: const InputDecoration(labelText: 'Maç Numarası', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => matchNumber = v),
              const SizedBox(height: 16),
              TextFormField(decoration: const InputDecoration(labelText: 'Takım Numarası', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => teamNumber = v),
              const SizedBox(height: 16),
              TextFormField(decoration: const InputDecoration(labelText: 'Puan (1-100)', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => score = v),
              const SizedBox(height: 16),
              TextFormField(decoration: const InputDecoration(labelText: 'Notlar', border: OutlineInputBorder()), maxLines: 5, onChanged: (v) => notes = v),

              const SizedBox(height: 20),
              ElevatedButton.icon(onPressed: pickImages, icon: const Icon(Icons.photo_library), label: const Text('Fotoğraf Ekle (Birden Fazla)')),
              if (selectedImages.isNotEmpty)
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedImages.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.memory(selectedImages[index], height: 140),
                    ),
                  ),
                ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (score.isEmpty) return;
                    final supabase = Supabase.instance.client;

                    List<String> photoUrls = [];
                    for (var image in selectedImages) {
                      try {
                        final fileName = '${teamNumber.isNotEmpty ? teamNumber : "team"}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        await supabase.storage.from('scouting_photos').uploadBinary(fileName, image);
                        photoUrls.add(supabase.storage.from('scouting_photos').getPublicUrl(fileName));
                      } catch (e) {
                        print("Fotoğraf hatası: $e");
                      }
                    }

                    if (editingId != null) {
                      await supabase.from('scouting_reports').update({
                        'match_number': int.tryParse(matchNumber),
                        'team_number': int.tryParse(teamNumber),
                        'score': int.tryParse(score),
                        'notes': notes,
                        if (photoUrls.isNotEmpty) 'photo_url': photoUrls.join(','),
                      }).eq('id', editingId!);
                    } else {
                      await supabase.from('scouting_reports').insert({
                        'match_number': int.tryParse(matchNumber),
                        'team_number': int.tryParse(teamNumber),
                        'score': int.tryParse(score),
                        'notes': notes,
                        'scouted_by': widget.userName,
                        if (photoUrls.isNotEmpty) 'photo_url': photoUrls.join(','),
                        'created_at': DateTime.now().toIso8601String(),
                      });
                    }

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Kaydedildi!')));

                    setState(() {
                      matchNumber = '';
                      teamNumber = '';
                      score = '';
                      notes = '';
                      selectedImages = [];
                      editingId = null;
                    });
                  },
                  child: Text(editingId != null ? 'Güncelle' : 'Kaydet', style: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================== KİŞİNİN SCOUTLARI ======================
class MyScoutsPage extends StatelessWidget {
  final String userName;
  const MyScoutsPage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Benim Scoutinglarım')),
      body: FutureBuilder<List<dynamic>>(
        future: Supabase.instance.client.from('scouting_reports').select().eq('scouted_by', userName.trim()).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data ?? [];

          if (data.isEmpty) return const Center(child: Text('Henüz scouting kaydın yok.'));

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text('Maç ${item['match_number']} - Takım ${item['team_number']}'),
                  subtitle: Text(item['notes']?.toString() ?? ''),
                  trailing: Text('${item['score']} Puan', style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.pop(context, item),
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sil?'),
                        content: const Text('Bu kaydı silmek istediğinden emin misin?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                          TextButton(onPressed: () async {
                            await Supabase.instance.client.from('scouting_reports').delete().eq('id', item['id']);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silindi')));
                            (context as Element).markNeedsBuild();
                          }, child: const Text('Sil', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ====================== ADMIN PANELİ ======================
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(tabs: [Tab(text: 'Takım Sıralaması'), Tab(text: 'Tüm Kayıtlar')]),
            Expanded(
              child: TabBarView(
                children: [
                  FutureBuilder(
                    future: Supabase.instance.client.from('scouting_reports').select('team_number, score'),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final data = snapshot.data as List;
                      Map<String, List<int>> teams = {};
                      for (var item in data) {
                        String team = item['team_number'].toString();
                        teams.putIfAbsent(team, () => []).add(item['score'] ?? 0);
                      }
                      var sorted = teams.entries.toList()..sort((a, b) => (b.value.reduce((x, y) => x+y) / b.value.length).compareTo(a.value.reduce((x, y) => x+y) / a.value.length));

                      return ListView.builder(
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          var avg = sorted[index].value.reduce((x, y) => x + y) / sorted[index].value.length;
                          return ListTile(leading: Text('${index+1}.'), title: Text('Takım ${sorted[index].key}'), trailing: Text('${avg.toStringAsFixed(1)} Puan'));
                        },
                      );
                    },
                  ),
                  FutureBuilder(
                    future: Supabase.instance.client.from('scouting_reports').select().order('created_at', ascending: false),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final data = snapshot.data as List;
                      return ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final item = data[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              title: Text('Maç ${item['match_number']} - Takım ${item['team_number']}'),
                              subtitle: Text('${item['scouted_by']} • ${item['notes']}'),
                              trailing: Text('${item['score']} Puan'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
