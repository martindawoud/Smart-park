// lib/screens/admin/admin_panel_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../providers/parking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';

class AdminPanelTab extends StatefulWidget {
  const AdminPanelTab({super.key});
  @override
  State<AdminPanelTab> createState() => _AdminPanelTabState();
}

class _AdminPanelTabState extends State<AdminPanelTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.card,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: const Color(0xFF9E9E9E),
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'Parking Slots'),
              Tab(text: 'Users'),
              Tab(text: 'Announcements'),
              Tab(text: 'Rules'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _SlotsSection(),
              _UsersSection(),
              _AnnouncementsSection(),
              _RulesSection(),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SLOTS SECTION
// ═══════════════════════════════════════════════════════════
class _SlotsSection extends StatelessWidget {
  const _SlotsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<ParkingProvider>(
      builder: (ctx, p, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: p.slots.isEmpty
            ? const _EmptySection(icon: Icons.local_parking_rounded, label: 'No parking slots')
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: p.slots.length,
                itemBuilder: (_, i) {
                  final s = p.slots[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: s.sensorHealth == 'fault'
                              ? AppColors.slotFaultBg
                              : s.isOccupied
                                  ? AppColors.slotOccupiedBg
                                  : AppColors.slotVacantBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(s.label,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: s.sensorHealth == 'fault'
                                      ? AppColors.slotFaultFg
                                      : s.isOccupied
                                          ? AppColors.slotOccupiedFg
                                          : AppColors.slotVacantFg)),
                        ),
                      ),
                      title: Text(s.sensorId),
                      subtitle: Text(
                        'Row ${s.posRow}, Col ${s.posCol} · ${s.sensorHealth.toUpperCase()}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _chipStatus(s),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.primary, size: 20),
                            onPressed: () => _showSlotDialog(ctx, p, slot: s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error, size: 20),
                            onPressed: () =>
                                _confirmDelete(ctx, 'slot "${s.label}"',
                                    () => p.deleteSlot(s.id)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showSlotDialog(ctx, p),
          icon: const Icon(Icons.add),
          label: const Text('Add Slot'),
        ),
      ),
    );
  }

  Widget _chipStatus(ParkingSlotModel s) {
    String label;
    Color bg, fg;
    if (s.sensorHealth == 'fault') {
      label = 'Fault'; bg = AppColors.slotFaultBg; fg = AppColors.slotFaultFg;
    } else if (s.sensorHealth == 'offline') {
      label = 'Offline'; bg = AppColors.slotOfflineBg; fg = AppColors.slotOfflineFg;
    } else if (s.isOccupied) {
      label = 'Occupied'; bg = AppColors.slotOccupiedBg; fg = AppColors.slotOccupiedFg;
    } else {
      label = 'Free'; bg = AppColors.slotVacantBg; fg = AppColors.slotVacantFg;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w700)),
    );
  }

  void _showSlotDialog(BuildContext ctx, ParkingProvider p,
      {ParkingSlotModel? slot}) {
    final labelCtrl = TextEditingController(text: slot?.label);
    final sensorCtrl = TextEditingController(text: slot?.sensorId);
    final rowCtrl =
        TextEditingController(text: slot?.posRow.toString() ?? '0');
    final colCtrl =
        TextEditingController(text: slot?.posCol.toString() ?? '0');
    final key = GlobalKey<FormState>();

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(slot == null ? 'Add Parking Slot' : 'Edit Slot'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(labelCtrl, 'Slot Label', 'e.g. C1'),
              const SizedBox(height: 12),
              _field(sensorCtrl, 'Sensor ID', 'e.g. IR-07'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field(rowCtrl, 'Row', '0',
                    inputType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _field(colCtrl, 'Column', '0',
                    inputType: TextInputType.number)),
              ]),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: Size.zero),
            onPressed: () async {
              if (!key.currentState!.validate()) return;
              final s = ParkingSlotModel(
                id: slot?.id ?? const Uuid().v4(),
                label: labelCtrl.text.trim().toUpperCase(),
                sensorId: sensorCtrl.text.trim().toUpperCase(),
                posRow: int.tryParse(rowCtrl.text) ?? 0,
                posCol: int.tryParse(colCtrl.text) ?? 0,
                isOccupied: slot?.isOccupied ?? false,
                sensorHealth: slot?.sensorHealth ?? 'ok',
                lastUpdated: DateTime.now().toIso8601String(),
                reservedBy: slot?.reservedBy,
                reservedUntil: slot?.reservedUntil,
                reservationId: slot?.reservationId,
              );
              if (slot == null) {
                await p.addSlot(s);
              } else {
                await p.updateSlot(s);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(slot == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// USERS SECTION
// ═══════════════════════════════════════════════════════════
class _UsersSection extends StatefulWidget {
  const _UsersSection();
  @override
  State<_UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<_UsersSection> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Consumer2<ParkingProvider, AuthProvider>(
      builder: (ctx, p, auth, _) {
        final users = p.users.where((u) =>
            u.name.toLowerCase().contains(_search.toLowerCase()) ||
            u.studentId.toLowerCase().contains(_search.toLowerCase())).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    hintText: 'Search by name or Student ID',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: users.isEmpty
                    ? const _EmptySection(
                        icon: Icons.people_outline, label: 'No users found')
                    : ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (_, i) {
                          final u = users[i];
                          final isSelf = auth.currentUser?.id == u.id;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: u.role == 'ADMIN'
                                    ? const Color(0xFFFFE0B2)
                                    : AppColors.primaryContainer,
                                child: Text(
                                  u.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: u.role == 'ADMIN'
                                        ? const Color(0xFFFF6F00)
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                              title: Text(u.name),
                              subtitle: Text('${u.studentId} · ${u.email}',
                                  style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _roleChip(u.role),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: AppColors.primary, size: 20),
                                    onPressed: () =>
                                        _showUserDialog(ctx, p, user: u),
                                  ),
                                  Tooltip(
                                    message: isSelf
                                        ? 'Cannot delete your own account'
                                        : 'Delete',
                                    child: IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          color: isSelf
                                              ? const Color(0xFFCCCCCC)
                                              : AppColors.error,
                                          size: 20),
                                      onPressed: isSelf
                                          ? null
                                          : () => _confirmDelete(
                                              ctx,
                                              'user "${u.name}"',
                                              () => p.deleteUser(u.id)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showUserDialog(ctx, p),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Add User'),
          ),
        );
      },
    );
  }

  Widget _roleChip(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: role == 'ADMIN'
            ? const Color(0xFFFFE0B2)
            : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(role,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: role == 'ADMIN'
                  ? const Color(0xFFFF6F00)
                  : AppColors.primary)),
    );
  }

  void _showUserDialog(BuildContext ctx, ParkingProvider p,
      {UserModel? user}) {
    final nameCtrl = TextEditingController(text: user?.name);
    final idCtrl = TextEditingController(text: user?.studentId);
    final pwCtrl = TextEditingController(text: user?.password);
    final emailCtrl = TextEditingController(text: user?.email);
    String role = user?.role ?? 'STUDENT';
    final key = GlobalKey<FormState>();

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (sCtx, setSt) => AlertDialog(
          title: Text(user == null ? 'Add User' : 'Edit User'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _field(nameCtrl, 'Full Name', 'e.g. Ali Hassan'),
                const SizedBox(height: 12),
                _field(idCtrl, 'Student ID', 'e.g. STU-2024010'),
                const SizedBox(height: 12),
                _field(pwCtrl, 'Password', ''),
                const SizedBox(height: 12),
                _field(emailCtrl, 'Email', 'e.g. ali@uni.edu',
                    inputType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'STUDENT', child: Text('Student')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                  ],
                  onChanged: (v) => setSt(() => role = v!),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(sCtx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: Size.zero),
              onPressed: () async {
                if (!key.currentState!.validate()) return;
                final u = UserModel(
                  id: user?.id ?? const Uuid().v4(),
                  studentId: idCtrl.text.trim(),
                  password: pwCtrl.text,
                  role: role,
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  createdAt: user?.createdAt ?? DateTime.now().toIso8601String(),
                );
                if (user == null) {
                  await p.addUser(u);
                } else {
                  await p.updateUser(u);
                }
                if (sCtx.mounted) Navigator.pop(sCtx);
              },
              child: Text(user == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ANNOUNCEMENTS SECTION
// ═══════════════════════════════════════════════════════════
class _AnnouncementsSection extends StatelessWidget {
  const _AnnouncementsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer2<ParkingProvider, AuthProvider>(
      builder: (ctx, p, auth, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: p.announcements.isEmpty
            ? const _EmptySection(
                icon: Icons.campaign_outlined, label: 'No announcements')
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: p.announcements.length,
                itemBuilder: (_, i) {
                  final a = p.announcements[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(a.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                              if (a.isExpired)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.slotOfflineBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Expired',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.slotOfflineFg,
                                          fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(a.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF546E7A))),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Expires: ${a.expiryDate.substring(0, 10)}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF9E9E9E))),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: AppColors.primary, size: 18),
                                    onPressed: () =>
                                        _showDialog(ctx, p, auth, a: a),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: AppColors.error, size: 18),
                                    onPressed: () => _confirmDelete(ctx,
                                        'announcement "${a.title}"',
                                        () => p.deleteAnnouncement(a.id)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showDialog(ctx, p, auth),
          icon: const Icon(Icons.add),
          label: const Text('New Announcement'),
        ),
      ),
    );
  }

  void _showDialog(BuildContext ctx, ParkingProvider p, AuthProvider auth,
      {AnnouncementModel? a}) {
    final titleCtrl = TextEditingController(text: a?.title);
    final bodyCtrl = TextEditingController(text: a?.body);
    final expiryCtrl = TextEditingController(
        text: a?.expiryDate.substring(0, 10) ?? '');
    DateTime? selectedDate = a != null ? DateTime.tryParse(a.expiryDate) : null;
    final key = GlobalKey<FormState>();

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (sCtx, setSt) => AlertDialog(
          title: Text(a == null ? 'New Announcement' : 'Edit Announcement'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _field(titleCtrl, 'Title', 'Announcement title'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bodyCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Body',
                    hintText: 'Announcement details',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: sCtx,
                      initialDate: selectedDate ??
                          DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365)),
                    );
                    if (d != null) {
                      setSt(() {
                        selectedDate = d;
                        expiryCtrl.text =
                            DateFormat('yyyy-MM-dd').format(d);
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: expiryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Select a date' : null,
                    ),
                  ),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(sCtx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: Size.zero),
              onPressed: () async {
                if (!key.currentState!.validate()) return;
                final model = AnnouncementModel(
                  id: a?.id ?? const Uuid().v4(),
                  title: titleCtrl.text.trim(),
                  body: bodyCtrl.text.trim(),
                  expiryDate: expiryCtrl.text,
                  createdAt: a?.createdAt ?? DateTime.now().toIso8601String(),
                  createdBy: auth.currentUser?.id ?? '',
                );
                if (a == null) {
                  await p.addAnnouncement(model);
                } else {
                  await p.updateAnnouncement(model);
                }
                if (sCtx.mounted) Navigator.pop(sCtx);
              },
              child: Text(a == null ? 'Publish' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// RULES SECTION
// ═══════════════════════════════════════════════════════════
class _RulesSection extends StatelessWidget {
  const _RulesSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<ParkingProvider>(
      builder: (ctx, p, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: p.rules.isEmpty
            ? const _EmptySection(
                icon: Icons.rule_outlined, label: 'No rules added')
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: p.rules.length,
                itemBuilder: (_, i) {
                  final r = p.rules[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.schedule_rounded,
                            color: AppColors.primary),
                      ),
                      title: Text(r.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.schedule,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500)),
                          Text(r.description,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF546E7A))),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.primary, size: 20),
                            onPressed: () => _showRuleDialog(ctx, p, rule: r),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error, size: 20),
                            onPressed: () => _confirmDelete(ctx,
                                'rule "${r.title}"', () => p.deleteRule(r.id)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showRuleDialog(ctx, p),
          icon: const Icon(Icons.add),
          label: const Text('Add Rule'),
        ),
      ),
    );
  }

  void _showRuleDialog(BuildContext ctx, ParkingProvider p,
      {ParkingRuleModel? rule}) {
    final titleCtrl = TextEditingController(text: rule?.title);
    final schedCtrl = TextEditingController(text: rule?.schedule);
    final descCtrl = TextEditingController(text: rule?.description);
    final key = GlobalKey<FormState>();

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(rule == null ? 'Add Rule' : 'Edit Rule'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(titleCtrl, 'Title', 'e.g. Campus Parking Hours'),
              const SizedBox(height: 12),
              _field(schedCtrl, 'Schedule', 'e.g. Mon–Fri 7AM–10PM'),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: Size.zero),
            onPressed: () async {
              if (!key.currentState!.validate()) return;
              final model = ParkingRuleModel(
                id: rule?.id ?? const Uuid().v4(),
                title: titleCtrl.text.trim(),
                schedule: schedCtrl.text.trim(),
                description: descCtrl.text.trim(),
                createdAt: rule?.createdAt ?? DateTime.now().toIso8601String(),
              );
              if (rule == null) {
                await p.addRule(model);
              } else {
                await p.updateRule(model);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(rule == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SHARED HELPERS
// ═══════════════════════════════════════════════════════════
TextFormField _field(
    TextEditingController ctrl, String label, String hint,
    {TextInputType? inputType}) {
  return TextFormField(
    controller: ctrl,
    keyboardType: inputType,
    decoration: InputDecoration(labelText: label, hintText: hint),
    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
  );
}

void _confirmDelete(BuildContext ctx, String label, VoidCallback onConfirm) {
  showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      title: const Text('Confirm Delete'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Text('Delete $label? This cannot be undone.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error, minimumSize: Size.zero),
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptySection({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: const Color(0xFFCCCCCC)),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF9E9E9E), fontSize: 16)),
        ],
      ),
    );
  }
}
