import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ovufjclhczjjjtnxaipl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im92dWZqY2xoY3pqamp0bnhhaXBsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4Njc4NjIsImV4cCI6MjA5NjQ0Mzg2Mn0.VsCgnrPyFEmpiLIDGrsVGpl96g4tmCGpqVCl4rhS42o',
  );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FTC Türkiye Alliance',
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
  final _teamNameController = TextEditingController();
  final _teamNumberController = TextEditingController();
  final _adminPass = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FTC Türkiye Alliance', style: TextStyle(fontSize: 20)),
            Text('Beta', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Hoş Geldin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'İsminiz', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _teamNameController, decoration: const InputDecoration(labelText: 'Takım Adı', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _teamNumberController, decoration: const InputDecoration(labelText: 'Takım Numarası', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isEmpty || _teamNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İsim ve Takım Adı zorunlu')));
                  return;
                }
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomePage(
                      userName: _nameController.text.trim(),
                      teamName: _teamNameController.text.trim(),
                      teamNumber: _teamNumberController.text.trim(),
                    ),
                  ),
                );
              },
              child: const Text('Giriş Yap', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 40),
            const Text("Admin Girişi"),
            TextField(controller: _adminPass, decoration: const InputDecoration(labelText: 'Admin Şifresi', border: OutlineInputBorder()), obscureText: true),
            ElevatedButton(onPressed: () {
              if (_adminPass.text == "asteria2026") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPage()));
            }, child: const Text('Admin Paneli')),
          ]),
        ),
      ),
    );
  }
}


// ====================== ANA SAYFA ======================
class HomePage extends StatefulWidget {
  final String userName;
  final String teamName;
  final String teamNumber;
  const HomePage({super.key, required this.userName, required this.teamName, required this.teamNumber});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? currentMatch;
  bool isLoading = true;
  Timer? _refreshTimer;

  // ====================== MANUEL KONTROLLER ======================
  bool hasLiveEvent = false;      // ← Canlı etkinlik var mı?
  bool hasUpcomingEvent = false;   // ← Yaklaşan etkinlik var mı?

  @override
  void initState() {
    super.initState();
    if (hasLiveEvent || hasUpcomingEvent) {
      fetchClosestMatch();
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => fetchClosestMatch());
    }
  }

  Future<void> fetchClosestMatch() async {
    // Eğer canlı etkinlik kapalıysa ve sadece upcoming varsa geri sayım göster
    if (!hasLiveEvent) {
      setState(() {
        currentMatch = null;
        isLoading = false;
      });
      return;
    }

    const String nexusApiKey = "pmU-SW8Op2SwIp5O_RzSmJOFRqg";
    const String eventKey = "demo3115";

    try {
      final response = await http.get(
        Uri.parse('https://ftc.nexus/api/v1/event/$eventKey'),
        headers: {'Nexus-Api-Key': nexusApiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matches = data['matches'] as List? ?? [];

        if (matches.isEmpty) {
          setState(() => currentMatch = null);
          return;
        }

        final now = DateTime.now().millisecondsSinceEpoch;
        var closestMatch = matches[0];
        int minDifference = 999999999999;

        for (var match in matches) {
          final estimatedTime = match['times']?['estimatedStartTime'] as int? ?? 0;
          final difference = (estimatedTime - now).abs();

          if (difference < minDifference) {
            minDifference = difference;
            closestMatch = match;
          }
        }

        setState(() {
          currentMatch = {
            "eventName": data['eventName'] ?? 'FTC Etkinliği',
            "division": closestMatch['division'] ?? '',
            "matchLabel": closestMatch['label'] ?? 'Qualification ?',
            "timeLeft": closestMatch['timeLeft'] ?? '??:??',
            "redTeams": closestMatch['redTeams'] ?? [],
            "blueTeams": closestMatch['blueTeams'] ?? [],
            "estimatedStartTime": _formatTimestamp(closestMatch['times']?['estimatedStartTime']),
            "isLive": closestMatch['status'] == 'On field' || closestMatch['status'] == 'ongoing',
          };
          isLoading = false;
        });
      }
    } catch (e) {
      print("Nexus API Hatası: $e");
      setState(() => isLoading = false);
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Bilinmiyor";
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "Bilinmiyor";
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Merhaba, ${widget.userName}')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Icon(Icons.groups, size: 100, color: Colors.blue),
              const Text('FTC Türkiye Alliance', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const Text('Türk FTC Takımları Dayanışma Platformu', style: TextStyle(fontSize: 18, color: Colors.grey)),

              const SizedBox(height: 40),

              if (isLoading)
                const CircularProgressIndicator()

              // İKİSİ DE FALSE İSE HİÇBİR ŞEY GÖSTERME
              else if (!hasLiveEvent && !hasUpcomingEvent)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Şu anda aktif bir etkinlik bulunmuyor.\nYakında yeni etkinlikler eklenecek.',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                )

              else if (currentMatch != null && hasLiveEvent)
                // ====================== CANLI MAÇ KARTI ======================
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        currentMatch!['eventName'],
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      if (currentMatch!['division'] != null && currentMatch!['division'] != '')
                        Text(
                          currentMatch!['division'],
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentMatch!['matchLabel'],
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Tahmini Başlangıç: ${currentMatch!['estimatedStartTime']}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text('KIRMIZI', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 8),
                                Text(
                                  (currentMatch!['redTeams'] as List).join(' • '),
                                  style: const TextStyle(color: Colors.white, fontSize: 17),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 40),
                          Expanded(
                            child: Column(
                              children: [
                                const Text('MAVİ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 8),
                                Text(
                                  (currentMatch!['blueTeams'] as List).join(' • '),
                                  style: const TextStyle(color: Colors.white, fontSize: 17),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Text(
                        currentMatch!['isLive'] == true ? 'ON FIELD' : '${currentMatch!['timeLeft']} left',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.yellow),
                      ),
                    ],
                  ),
                )
              else
                // ====================== GERİ SAYIM ======================
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CountdownTimer(targetDate: DateTime(2026, 10, 18, 9, 0)),
                ),

              const SizedBox(height: 50),

              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostsPage())),
                child: const Text('Tüm Paylaşımlar', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyPostsPage(userName: widget.userName))),
                child: const Text('Benim Paylaşımlarım', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewPostPage(userName: widget.userName, teamName: widget.teamName, teamNumber: widget.teamNumber))),
                child: const Text('Yeni Paylaşım Yap', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================== GERİ SAYIM WIDGET ======================
class CountdownTimer extends StatefulWidget {
  final DateTime targetDate;
  const CountdownTimer({super.key, required this.targetDate});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateRemaining());
  }

  void _calculateRemaining() {
    setState(() {
      _remaining = widget.targetDate.difference(DateTime.now());
      if (_remaining.isNegative) _remaining = Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int days = _remaining.inDays;
    int hours = _remaining.inHours % 24;
    int minutes = _remaining.inMinutes % 60;
    int seconds = _remaining.inSeconds % 60;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeBox(days, 'GÜN'),
            _buildTimeBox(hours, 'SAAT'),
            _buildTimeBox(minutes, 'DAKİKA'),
            _buildTimeBox(seconds, 'SANİYE'),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeBox(int value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.toString().padLeft(2, '0'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}


// ====================== TÜM PAYLAŞIMLAR ======================
class PostsPage extends StatefulWidget {
  const PostsPage({super.key});
  @override State<PostsPage> createState() => _PostsPageState();
}


class _PostsPageState extends State<PostsPage> {
  String selectedCategory = 'Tümü';
  String sortBy = 'newest';


  final List<String> categories = ['Tümü', 'Genel', 'Robot', 'Kod', 'Strateji', 'Yardım', 'Organizasyon', 'Diğer'];


  @override
  Widget build(BuildContext context) {
    String orderBy = sortBy == 'likes' ? 'like' : 'created_at';
    bool ascending = sortBy == 'oldest';


    return Scaffold(
      appBar: AppBar(title: const Text('Tüm Paylaşımlar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (value) => setState(() => selectedCategory = value!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: sortBy,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text('En Yeni')),
                      DropdownMenuItem(value: 'oldest', child: Text('En Eski')),
                      DropdownMenuItem(value: 'likes', child: Text('En Çok Beğenilen')),
                    ],
                    onChanged: (value) => setState(() => sortBy = value!),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: Supabase.instance.client.from('alliance_posts').select().order(orderBy, ascending: ascending),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final data = snapshot.data ?? [];
                final filtered = selectedCategory == 'Tümü' ? data : data.where((p) => p['category'] == selectedCategory).toList();


                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final post = filtered[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(post['title'] ?? 'Başlıksız'),
                        subtitle: Text(post['content']?.toString() ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () async {
                                await Supabase.instance.client
                                    .from('alliance_posts')
                                    .update({'like': (post['like'] ?? 0) + 1})
                                    .eq('id', post['id']);
                                setState(() {});
                              },
                            ),
                            Text('${post['like'] ?? 0}'),
                          ],
                        ),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(post: post))),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


// ====================== PAYLAŞIM DETAY + YORUMLAR ======================
class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostDetailPage({super.key, required this.post});


  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}


class _PostDetailPageState extends State<PostDetailPage> {
  final _commentController = TextEditingController();
  String? editingCommentId;


  @override
  Widget build(BuildContext context) {
    final photos = (widget.post['photo_url'] as String?)?.split(',').map((e) => e.trim()).toList() ?? [];


    return Scaffold(
      appBar: AppBar(title: Text(widget.post['title'] ?? '')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Takım: ${widget.post['team_name']}'),
                  Text('Yazan: ${widget.post['author_name']}'),
                  const SizedBox(height: 12),
                  Text(widget.post['content']?.toString() ?? ''),
                  const Divider(height: 30),
                  const Text('Fotoğraflar (Linkler):', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (photos.isEmpty)
                    const Text('Fotoğraf yok')
                  else
                    Column(
                      children: photos.map((url) => ListTile(
                        leading: const Icon(Icons.link, color: Colors.blue),
                        title: Text(url.length > 60 ? '${url.substring(0, 57)}...' : url, style: const TextStyle(color: Colors.blue)),
                        onTap: () => launchUrl(Uri.parse(url)),
                      )).toList(),
                    ),
                  const Divider(height: 30),
                  const Text('Yorumlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  FutureBuilder<List<dynamic>>(
                    future: Supabase.instance.client.from('alliance_comments').select().eq('post_id', widget.post['id']).order('created_at'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                      final comments = snapshot.data ?? [];
                      if (comments.isEmpty) return const Text('Henüz yorum yok.');


                      return Column(
                        children: comments.map((comment) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                           
                            //title: Text(comment['author_name']),
                            subtitle: Text(comment['content']),
                            trailing: comment['author_name'] == widget.post['author_name'] ? Row(
                              mainAxisSize: MainAxisSize.min,
                              /*children: [
                                IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () {
                                  setState(() {
                                    editingCommentId = comment['id'];
                                    _commentController.text = comment['content'];
                                  });
                                }),
                                IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () async {
                                  await Supabase.instance.client.from('alliance_comments').delete().eq('id', comment['id']);
                                  setState(() {});
                                }),
                              ], */
                            ) : null,
                          ),
                        )).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: editingCommentId != null ? 'Yorumu düzenle...' : 'Yorum yaz...',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (_commentController.text.isEmpty) return;
                    final supabase = Supabase.instance.client;


                    if (editingCommentId != null) {
                      await supabase.from('alliance_comments').update({'content': _commentController.text}).eq('id', editingCommentId!);
                      editingCommentId = null;
                    } else {
                      await supabase.from('alliance_comments').insert({
                        'post_id': widget.post['id'],
                        'author_name': widget.post['author_name'],
                        'content': _commentController.text,
                      });
                    }
                    _commentController.clear();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ====================== BENİM PAYLAŞIMLARIM ======================
class MyPostsPage extends StatelessWidget {
  final String userName;
  const MyPostsPage({super.key, required this.userName});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Benim Paylaşımlarım')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.orange.shade800,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '⚠️ Paylaşımlarınız 90 gün sonra otomatik olarak silinecektir.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: Supabase.instance.client.from('alliance_posts').select().eq('author_name', userName).order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final data = snapshot.data ?? [];
                if (data.isEmpty) return const Center(child: Text('Henüz paylaşımın yok.'));


                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final post = data[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(post['title'] ?? ''),
                        subtitle: Text(post['content']?.toString() ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewPostPage(
                                userName: userName,
                                teamName: post['team_name'] ?? '',
                                teamNumber: post['team_number']?.toString() ?? '',
                                editingPost: post,
                              ))),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Sil?'),
                                    content: const Text('Bu paylaşımı silmek istediğinden emin misin?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                                      TextButton(
                                        onPressed: () async {
                                          await Supabase.instance.client.from('alliance_posts').delete().eq('id', post['id']);
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silindi')));
                                          (context as Element).markNeedsBuild();
                                        },
                                        child: const Text('Sil', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


// ====================== YENİ / DÜZENLE PAYLAŞIM ======================
class NewPostPage extends StatefulWidget {
  final String userName;
  final String teamName;
  final String teamNumber;
  final Map<String, dynamic>? editingPost;
  const NewPostPage({super.key, required this.userName, required this.teamName, required this.teamNumber, this.editingPost});
  @override State<NewPostPage> createState() => _NewPostPageState();
}


class _NewPostPageState extends State<NewPostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String category = 'Genel';
  List<Uint8List> selectedImages = [];


  final ImagePicker _picker = ImagePicker();


  @override
  void initState() {
    super.initState();
    if (widget.editingPost != null) {
      _titleController.text = widget.editingPost!['title'] ?? '';
      _contentController.text = widget.editingPost!['content'] ?? '';
      category = widget.editingPost!['category'] ?? 'Genel';
    }
  }


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
      appBar: AppBar(title: const Text('Yeni / Düzenle Paylaşım')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Başlık', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: category,
              items: ['Genel', 'Robot', 'Kod', 'Strateji', 'Yardım', 'Organizasyon', 'Diğer']
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (value) => setState(() => category = value!),
              decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(controller: _contentController, decoration: const InputDecoration(labelText: 'İçerik', border: OutlineInputBorder()), maxLines: 8),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: pickImages, icon: const Icon(Icons.photo_library), label: const Text('Fotoğraf Ekle')),
            if (selectedImages.isNotEmpty) Text('${selectedImages.length} fotoğraf seçildi'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty) return;
                final supabase = Supabase.instance.client;


                List<String> photoUrls = [];
                for (var image in selectedImages) {
                  try {
                    final fileName = '${widget.teamNumber}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    await supabase.storage.from('ftc_alliance_photos').uploadBinary(fileName, image);
                    photoUrls.add(supabase.storage.from('ftc_alliance_photos').getPublicUrl(fileName));
                  } catch (e) {
                    print("Fotoğraf hatası: $e");
                  }
                }


                if (widget.editingPost != null) {
                  await supabase.from('alliance_posts').update({
                    'title': _titleController.text,
                    'content': _contentController.text,
                    'category': category,
                    if (photoUrls.isNotEmpty) 'photo_url': photoUrls.join(','),
                  }).eq('id', widget.editingPost!['id']);
                } else {
                  await supabase.from('alliance_posts').insert({
                    'title': _titleController.text,
                    'content': _contentController.text,
                    'category': category,
                    'author_name': widget.userName,
                    'team_name': widget.teamName,
                    'team_number': int.tryParse(widget.teamNumber),
                    'like': 0,
                    if (photoUrls.isNotEmpty) 'photo_url': photoUrls.join(','),
                    'created_at': DateTime.now().toIso8601String(),
                  });
                }


                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ İşlem tamamlandı!')));
              },
              child: Text(widget.editingPost != null ? 'Güncelle' : 'Paylaş', style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
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
                    future: Supabase.instance.client.from('alliance_posts').select('team_number, like'),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final data = snapshot.data as List;
                      Map<String, List<int>> teams = {};
                      for (var item in data) {
                        String team = item['team_number'].toString();
                        teams.putIfAbsent(team, () => []).add(item['like'] ?? 0);
                      }
                      var sorted = teams.entries.toList()..sort((a, b) => (b.value.reduce((x, y) => x+y) / b.value.length).compareTo(a.value.reduce((x, y) => x+y) / a.value.length));


                      return ListView.builder(
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          var avg = sorted[index].value.reduce((x, y) => x + y) / sorted[index].value.length;
                          return ListTile(leading: Text('${index+1}.'), title: Text('Takım ${sorted[index].key}'), trailing: Text('${avg.toStringAsFixed(1)} Beğeni'));
                        },
                      );
                    },
                  ),
                  FutureBuilder(
                    future: Supabase.instance.client.from('alliance_posts').select().order('created_at', ascending: false),
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
                              title: Text(item['title'] ?? ''),
                              subtitle: Text('${item['author_name']} • ${item['team_name']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Sil?'),
                                      content: const Text('Bu paylaşımı silmek istediğinden emin misin?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                                        TextButton(
                                          onPressed: () async {
                                            await Supabase.instance.client.from('alliance_posts').delete().eq('id', item['id']);
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silindi')));
                                            (context as Element).markNeedsBuild();
                                          },
                                          child: const Text('Sil', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
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
