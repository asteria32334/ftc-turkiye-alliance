import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FTC Türkiye Alliance')),
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
            const SizedBox(height: 40),
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
          ]),
        ),
      ),
    );
  }
}

// ====================== ANA SAYFA ======================
class HomePage extends StatelessWidget {
  final String userName;
  final String teamName;
  final String teamNumber;
  const HomePage({super.key, required this.userName, required this.teamName, required this.teamNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Merhaba, $userName')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups, size: 120, color: Colors.blue),
            const SizedBox(height: 30),
            const Text('FTC Türkiye Alliance', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const Text('Türk FTC Takımları Dayanışma Platformu', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostsPage())),
              child: const Text('Tüm Paylaşımlar', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyPostsPage(userName: userName))),
              child: const Text('Benim Paylaşımlarım', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewPostPage(userName: userName, teamName: teamName, teamNumber: teamNumber))),
              child: const Text('Yeni Paylaşım Yap', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== TÜM PAYLAŞIMLAR ======================
class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tüm Paylaşımlar')),
      body: FutureBuilder<List<dynamic>>(
        future: Supabase.instance.client.from('alliance_posts').select().order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data ?? [];
          if (data.isEmpty) return const Center(child: Text('Henüz paylaşım yok.'));

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final post = data[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(post['title'] ?? 'Başlıksız'),
                  subtitle: Text(post['content']?.toString() ?? ''),
                  trailing: Text(post['team_name'] ?? ''),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(post: post))),
                ),
              );
            },
          );
        },
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
                            title: Text(comment['author_name']),
                            subtitle: Text(comment['content']),
                            trailing: comment['team_name'] == widget.post['team_name'] ? Row(  // Takım bazlı kontrol
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                              ],
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
                        'team_name': widget.post['team_name'],   // Takım bilgisi de kaydediliyor
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
      body: FutureBuilder<List<dynamic>>(
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
