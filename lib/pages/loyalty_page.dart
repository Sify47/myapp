import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class LoyaltyPage extends StatefulWidget {
  const LoyaltyPage({super.key});

  @override
  State<LoyaltyPage> createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends State<LoyaltyPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  int _points = 0;
  String _tier = 'مبتدئ';
  int _nextTierPoints = 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نقاط الولاء والمكافآت'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3366FF),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            _points = userData['loyaltyPoints'] ?? 0;
            _tier = _getTier(_points);
            _nextTierPoints = _getNextTierPoints(_points);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // بطاقة النقاط الرئيسية
                _buildPointsCard(),
                const SizedBox(height: 24),
                
                // شريط التقدم
                _buildProgressBar(),
                const SizedBox(height: 24),
                
                // المستويات
                _buildTiersSection(),
                const SizedBox(height: 24),
                
                // المكافآت المتاحة
                _buildAvailableRewards(),
                const SizedBox(height: 24),
                
                // تاريخ النقاط
                _buildPointsHistory(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPointsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3366FF), Color(0xFF6A11CB)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Text(
              'نقاط الولاء',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$_points',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'المستوى: $_tier',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('المكافآت', Icons.card_giftcard),
                _buildStatItem('النقاط', Icons.star),
                _buildStatItem('المستوى', Icons.emoji_events),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = _points / _nextTierPoints;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تقدمك نحو المستوى التالي',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress > 1 ? 1 : progress,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation(Color(0xFF3366FF)),
          minHeight: 12,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_points نقطة',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              '${_nextTierPoints - _points} نقطة متبقية',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTiersSection() {
    final tiers = [
      {'name': 'مبتدئ', 'points': 0, 'benefits': ['خصم 5%', 'هدية ترحيبية']},
      {'name': 'فضي', 'points': 100, 'benefits': ['خصم 10%', 'شحن مجاني', 'هدية شهرية']},
      {'name': 'ذهبي', 'points': 500, 'benefits': ['خصم 15%', 'شحن مجاني', 'هدايا حصرية', 'دعم مميز']},
      {'name': 'بلاتينيوم', 'points': 1000, 'benefits': ['خصم 20%', 'شحن فوري', 'هدايا VIP', 'دعم 24/7']},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مستويات الولاء',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...tiers.map((tier) => _buildTierCard(tier)).toList(),
      ],
    );
  }

  Widget _buildTierCard(Map<String, dynamic> tier) {
    final isCurrent = tier['name'] == _tier;
    final isUnlocked = _points >= tier['points'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrent ? const Color(0xFF3366FF) : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCurrent ? const Color(0xFF3366FF) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCurrent ? Icons.star : Icons.star_border,
            color: isCurrent ? Colors.white : Colors.grey,
          ),
        ),
        title: Text(
          tier['name'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCurrent ? const Color(0xFF3366FF) : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${tier['points']} نقطة'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: (tier['benefits'] as List).map((benefit) {
                return Chip(
                  label: Text(benefit),
                  backgroundColor: const Color(0xFF3366FF).withOpacity(0.1),
                  labelStyle: const TextStyle(fontSize: 12),
                );
              }).toList(),
            ),
          ],
        ),
        trailing: isCurrent
            ? const Icon(Icons.check_circle, color: Colors.green)
            : Icon(
                isUnlocked ? Icons.lock_open : Icons.lock_outline,
                color: isUnlocked ? Colors.green : Colors.grey,
              ),
      ),
    );
  }

  Widget _buildAvailableRewards() {
    final rewards = [
      {
        'title': 'خصم 10%',
        'points': 50,
        'description': 'خصم 10% على طلبك القادم',
        'icon': Icons.discount,
      },
      {
        'title': 'شحن مجاني',
        'points': 100,
        'description': 'شحن مجاني لمدة شهر',
        'icon': Icons.local_shipping,
      },
      {
        'title': 'هدية مفاجأة',
        'points': 200,
        'description': 'هدية مفاجأة مع طلبك',
        'icon': Icons.card_giftcard,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المكافآت المتاحة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
          children: rewards.map((reward) => _buildRewardCard(reward)).toList(),
        ),
      ],
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward) {
    final canRedeem = _points >= reward['points'];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: canRedeem ? () => _redeemReward(reward) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                reward['icon'],
                size: 32,
                color: canRedeem ? const Color(0xFF3366FF) : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                reward['title'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: canRedeem ? Colors.black : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                reward['description'],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: canRedeem
                      ? const Color(0xFF3366FF).withOpacity(0.1)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${reward['points']} نقطة',
                  style: TextStyle(
                    color: canRedeem ? const Color(0xFF3366FF) : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'سجل النقاط',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .collection('pointsHistory')
              .orderBy('date', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('لا توجد معاملات حتى الآن'),
              );
            }

            final transactions = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final data = transaction.data() as Map<String, dynamic>;
                
                return _buildTransactionItem(data);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> data) {
    final date = (data['date'] as Timestamp).toDate();
    final points = data['points'] as int;
    final reason = data['reason'] ?? '';
    final isEarned = points > 0;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isEarned
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isEarned ? Icons.add : Icons.remove,
          color: isEarned ? Colors.green : Colors.red,
        ),
      ),
      title: Text(reason),
      subtitle: Text(DateFormat('yyyy/MM/dd - hh:mm a').format(date)),
      trailing: Text(
        '${isEarned ? '+' : ''}$points',
        style: TextStyle(
          color: isEarned ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getTier(int points) {
    if (points >= 1000) return 'بلاتينيوم';
    if (points >= 500) return 'ذهبي';
    if (points >= 100) return 'فضي';
    return 'مبتدئ';
  }

  int _getNextTierPoints(int points) {
    if (points < 100) return 100;
    if (points < 500) return 500;
    if (points < 1000) return 1000;
    return 1000;
  }

  void _redeemReward(Map<String, dynamic> reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استبدال المكافأة'),
        content: Text('هل تريد استبدال ${reward['points']} نقطة مقابل ${reward['title']}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processRewardRedemption(reward);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Future<void> _processRewardRedemption(Map<String, dynamic> reward) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user?.uid);
    
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final currentPoints = userDoc['loyaltyPoints'] ?? 0;
      
      if (currentPoints >= reward['points']) {
        transaction.update(userRef, {
          'loyaltyPoints': FieldValue.increment(-reward['points']),
        });
        
        // إضافة إلى سجل المكافآت
        transaction.set(
          userRef.collection('rewards').doc(),
          {
            'title': reward['title'],
            'points': -reward['points'],
            'date': Timestamp.now(),
            'status': 'pending',
          },
        );
        
        // إضافة إلى سجل النقاط
        transaction.set(
          userRef.collection('pointsHistory').doc(),
          {
            'points': -reward['points'],
            'reason': 'استبدال مكافأة: ${reward['title']}',
            'date': Timestamp.now(),
          },
        );
      }
    });
  }
}