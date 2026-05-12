import 'package:flutter/material.dart';

class ExploreGroupDetailScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final Color bgColor;

  const ExploreGroupDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.bgColor,
  });

  @override
  State<ExploreGroupDetailScreen> createState() => _ExploreGroupDetailScreenState();
}

class _ExploreGroupDetailScreenState extends State<ExploreGroupDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _joined = false;

  final _descriptions = {
    'Muscat Runners': 'مجموعة جري أسبوعية في مسقط. مسارات متنوعة تناسب جميع المستويات من المبتدئين للمحترفين.',
    'Oman Cyclists': 'رحلات دراجات أسبوعية في مسقط ومحافظات عُمان. مسارات جبلية ومسارات طرق معتدلة.',
    'CrossFit Muscat': 'تمارين كروس فت جماعية يومية. تدريب عالي الكثافة مناسب لجميع مستويات اللياقة.',
    'Al Mouj Swimmers': 'سباحة مفتوحة في بحر الموج. تدريبات أسبوعية للمبتدئين والمتقدمين.',
  };

  final _tags = {
    'Muscat Runners': ['جري', 'ماراثون'],
    'Oman Cyclists': ['دراجات', 'جبلية'],
    'CrossFit Muscat': ['كروس فت', 'لياقة'],
    'Al Mouj Swimmers': ['سباحة', 'بحر'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final description = _descriptions[widget.title] ?? 'مجموعة رياضية مميّزة في عُمان.';
    final tags = _tags[widget.title] ?? ['رياضة'];
    final memberCount = widget.subtitle.replaceAll(RegExp(r'[^0-9]'), '');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: Column(
          children: [
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: _buildHeader(context, description, tags, memberCount),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(
                      tabBar: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF3B82F6),
                        unselectedLabelColor: Colors.grey[500],
                        indicatorColor: const Color(0xFF3B82F6),
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        tabs: const [
                          Tab(text: 'الدردشة'),
                          Tab(text: 'الأحداث'),
                          Tab(text: 'الأعضاء'),
                          Tab(text: 'المعلومات'),
                        ],
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChatTab(),
                    _buildEventsTab(),
                    _buildMembersTab(memberCount),
                    _buildInfoTab(description, tags),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String description, List<String> tags, String memberCount) {
    return Column(
      children: [
        // الخلفية + الأيقونة
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.bgColor,
              ),
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_forward_ios, size: 18),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -35,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: widget.bgColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 36))),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 44),

        // معلومات المجموعة
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // اسم المجموعة
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        Text(widget.subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  // زر الانضمام
                  GestureDetector(
                    onTap: () {
                      setState(() => _joined = !_joined);
                      if (_joined) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم الانضمام للمجموعة بنجاح! 🎉'), backgroundColor: Color(0xFF10B981)),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _joined ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _joined ? 'عضو ✓' : 'انضم للمجموعة',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // الوصف
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.6),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 14),
              // التاغات
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatTab() {
    if (!_joined) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('الدردشة متاحة للأعضاء فقط', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                setState(() => _joined = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم الانضمام للمجموعة بنجاح! 🎉'), backgroundColor: Color(0xFF10B981)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('انضم للمجموعة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 56, color: Color(0xFF10B981)),
          const SizedBox(height: 16),
          Text('أنت عضو الآن! الدردشة متاحة.', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildEventCard('جري الفجر — مسار القرم', '٢٥ أبريل', '23 مسجّل'),
        const SizedBox(height: 12),
        _buildEventCard('سباق ٥ك الخيري', '٣٠ أبريل', '178 مسجّل'),
      ],
    );
  }

  Widget _buildEventCard(String title, String date, String count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text('$date • $count', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          const Icon(Icons.calendar_today, color: Color(0xFF3B82F6)),
        ],
      ),
    );
  }

  Widget _buildMembersTab(String memberCount) {
    final names = ['فاطمة الحارثي', 'نور السعيدي', 'أحمد البلوشي', 'خالد الراشدي', 'سعيد المقبالي'];
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: names.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: CircleAvatar(
            backgroundColor: [
              const Color(0xFF3B82F6),
              const Color(0xFFF59E0B),
              const Color(0xFF10B981),
              const Color(0xFFEF4444),
              const Color(0xFF8B5CF6),
            ][index],
            child: Text(names[index][0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          title: Text(names[index], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(index == 0 ? 'مشرف' : 'عضو', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        );
      },
    );
  }

  Widget _buildInfoTab(String description, List<String> tags) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoRow(Icons.location_on_outlined, 'الموقع', 'مسقط، عُمان'),
        _buildInfoRow(Icons.calendar_today_outlined, 'تأسست', '2024'),
        _buildInfoRow(Icons.sports_outlined, 'النشاط', tags.join('، ')),
        _buildInfoRow(Icons.schedule_outlined, 'النشاط الأسبوعي', 'كل جمعة ٥:٣٠ صباحاً'),
        const SizedBox(height: 24),
        const Text('عن المجموعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.7)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF475569), size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate({required this.tabBar});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
