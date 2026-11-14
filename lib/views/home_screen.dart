import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/health_record.dart';
import '../viewmodels/health_view_model.dart';

String prettyDate(String value) =>
    DateFormat('EEE, d MMM yyyy').format(DateTime.parse(value));
void message(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int tab = 0;
  String? filter;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HealthViewModel>().load();
    }
  }

  Future<void> edit([HealthRecord? record]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => RecordScreen(record: record)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HealthViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.favorite_rounded),
            SizedBox(width: 10),
            Text('HealthMate', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: vm.loading ? null : vm.load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh records',
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                if (vm.loading) const LinearProgressIndicator(),
                if (vm.error != null)
                  MaterialBanner(
                    content: Text(vm.error!),
                    actions: [
                      TextButton(
                        onPressed: vm.load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: vm.load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                      children: tab == 0
                          ? dashboard(vm)
                          : tab == 1
                          ? records(vm)
                          : settings(vm),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: tab == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Add record'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Today',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Records'),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  List<Widget> dashboard(HealthViewModel vm) {
    final today = vm.totals(dateKey(DateTime.now()));
    return [
      Text(
        DateFormat('EEEE, d MMMM').format(DateTime.now()),
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(height: 8),
      Text(
        'A little better, every day.',
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'Your daily activity, all in one place. Add entries as you go; today\'s totals update automatically.',
      ),
      const SizedBox(height: 24),
      metric(
        'Steps walked',
        today.steps,
        'steps',
        Icons.directions_walk_rounded,
        Colors.green,
      ),
      const SizedBox(height: 12),
      metric(
        'Calories burned',
        today.calories,
        'kcal',
        Icons.local_fire_department_rounded,
        Colors.deepOrange,
      ),
      const SizedBox(height: 12),
      metric(
        'Water intake',
        today.water,
        'ml',
        Icons.water_drop_rounded,
        Colors.blue,
      ),
    ];
  }

  Widget metric(
    String label,
    int value,
    String unit,
    IconData icon,
    Color color,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${NumberFormat.decimalPattern().format(value)} $unit',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
  List<Widget> records(HealthViewModel vm) {
    final entries = vm.records
        .where((r) => filter == null || r.date == filter)
        .toList();
    return [
      Text(
        'Your health journal',
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text('Review your progress and keep every entry up to date.'),
      const SizedBox(height: 18),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: filter == null
                    ? DateTime.now()
                    : DateTime.parse(filter!),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (selected != null && mounted) {
                setState(() => filter = dateKey(selected));
              }
            },
            icon: const Icon(Icons.calendar_month),
            label: Text(
              filter == null ? 'Filter by date' : prettyDate(filter!),
            ),
          ),
          if (filter != null)
            TextButton(
              onPressed: () => setState(() => filter = null),
              child: const Text('Clear filter'),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Text('${entries.length} entries'),
      const SizedBox(height: 12),
      if (entries.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(Icons.event_note_outlined, size: 56),
              SizedBox(height: 16),
              Text('No records here yet.'),
              SizedBox(height: 8),
              Text('Add an entry or try a different date.'),
            ],
          ),
        ),
      ...entries.map(
        (record) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          prettyDate(record.date),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => edit(record),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit record',
                      ),
                      IconButton(
                        onPressed: () => deleteRecord(record),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete record',
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text('Steps: ${record.steps}'),
                      Text('Calories: ${record.calories} kcal'),
                      Text('Water: ${record.water} ml'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Future<void> deleteRecord(HealthRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text(
          'The entry for ${prettyDate(record.date)} will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final vm = context.read<HealthViewModel>();
    final success = await vm.delete(record.id!);
    if (mounted) message(context, success ? 'Record deleted' : vm.error!);
  }

  List<Widget> settings(HealthViewModel vm) => [
    Text(
      'Make it yours',
      style: Theme.of(
        context,
      ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 24),
    Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 12),
    DropdownButtonFormField<ThemeMode>(
      initialValue: vm.themeMode,
      decoration: const InputDecoration(
        labelText: 'App theme',
        prefixIcon: Icon(Icons.palette_outlined),
      ),
      items: const [
        DropdownMenuItem(
          value: ThemeMode.system,
          child: Text('System default'),
        ),
        DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
      ],
      onChanged: (value) async {
        if (value != null) {
          try {
            await vm.setTheme(value);
          } catch (_) {
            if (mounted) message(context, 'Could not save theme. Try again.');
          }
        }
      },
    ),
    const SizedBox(height: 28),
    Text('About', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 12),
    const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_rounded),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'HealthMate',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Your personal health and wellness tracker. Record your daily steps, calories burned and water intake, and review your activity history.',
            ),
          ],
        ),
      ),
    ),
  ];
}

class RecordScreen extends StatefulWidget {
  final HealthRecord? record;
  const RecordScreen({super.key, this.record});
  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController steps, calories, water;
  late DateTime date;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final r = widget.record;
    date = r == null ? DateTime.now() : DateTime.parse(r.date);
    steps = TextEditingController(text: r?.steps.toString());
    calories = TextEditingController(text: r?.calories.toString());
    water = TextEditingController(text: r?.water.toString());
  }

  @override
  void dispose() {
    steps.dispose();
    calories.dispose();
    water.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.record == null ? 'Add health record' : 'Edit health record',
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Record your activity',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add the amounts for this entry. Multiple entries on the same date are added together on your dashboard.',
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => date = picked);
                        },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(prettyDate(dateKey(date))),
                ),
                const SizedBox(height: 20),
                amountField(
                  steps,
                  'Steps walked',
                  'steps',
                  Icons.directions_walk,
                ),
                const SizedBox(height: 20),
                amountField(
                  calories,
                  'Calories burned',
                  'kcal',
                  Icons.local_fire_department_outlined,
                ),
                const SizedBox(height: 20),
                amountField(
                  water,
                  'Water intake',
                  'ml',
                  Icons.water_drop_outlined,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: saving ? null : save,
                  icon: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(saving ? 'Saving...' : 'Save record'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget amountField(
    TextEditingController controller,
    String label,
    String unit,
    IconData icon,
  ) => TextFormField(
    controller: controller,
    enabled: !saving,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    validator: validateAmount,
    decoration: InputDecoration(
      labelText: label,
      suffixText: unit,
      prefixIcon: Icon(icon),
    ),
    autovalidateMode: AutovalidateMode.onUserInteraction,
  );
  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    final vm = context.read<HealthViewModel>();
    final success = await vm.save(
      HealthRecord(
        id: widget.record?.id,
        date: dateKey(date),
        steps: int.parse(steps.text),
        calories: int.parse(calories.text),
        water: int.parse(water.text),
      ),
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (success) {
      Navigator.pop(context);
      message(context, 'Record saved');
    } else {
      message(context, vm.error!);
    }
  }
}
