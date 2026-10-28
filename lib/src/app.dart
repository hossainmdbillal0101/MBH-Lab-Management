import 'package:flutter/material.dart';
import 'store.dart';

const navy = Color(0xff142c3a),
    teal = Color(0xff166f68),
    paper = Color(0xfff3f6f6);

class LabApp extends StatelessWidget {
  final LabStore store;
  const LabApp({super.key, required this.store});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'MBH Lab Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: teal),
        scaffoldBackgroundColor: paper,
        appBarTheme: const AppBarTheme(
            backgroundColor: paper, foregroundColor: navy, elevation: 0),
        inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white),
        cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xffdce5e6)))),
      ),
      home: Workspace(store: store));
}

class Workspace extends StatefulWidget {
  final LabStore store;
  const Workspace({super.key, required this.store});
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  LabStore get s => widget.store;
  int page = 0;
  String search = '', lab = 'All labs', status = 'All statuses';
  final searchController = TextEditingController();
  static const tabs = ['Overview', 'Assets', 'Maintenance', 'Labs'];
  static const icons = [
    Icons.space_dashboard_outlined,
    Icons.computer_outlined,
    Icons.fact_check_outlined,
    Icons.domain_outlined
  ];
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void message(Object value) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value.toString().replaceFirst('Exception: ', ''))));
  Future<void> action(Future<void> Function() work) async {
    try {
      await work();
      if (mounted) message('Workspace updated.');
    } catch (_) {
      if (mounted) {
        message('Could not save. Check your access, inputs and connection.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: s,
      builder: (context, _) => LayoutBuilder(builder: (context, box) {
            final wide = box.maxWidth >= 1000;
            return Scaffold(
                appBar: AppBar(
                    title: const Text('MBH Lab Management',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 19)),
                    actions: [
                      if (s.live && !s.signedIn)
                        TextButton.icon(
                            onPressed: login,
                            icon: const Icon(Icons.lock_outline, size: 18),
                            label: const Text('Staff sign in')),
                      if (s.signedIn)
                        IconButton(
                            tooltip: 'Sign out',
                            onPressed: s.signOut,
                            icon: const Icon(Icons.logout)),
                      IconButton(
                          tooltip: 'About this workspace',
                          onPressed: about,
                          icon: const Icon(Icons.info_outline)),
                      const SizedBox(width: 8)
                    ]),
                bottomNavigationBar: wide
                    ? null
                    : NavigationBar(
                        selectedIndex: page,
                        onDestinationSelected: (i) => setState(() => page = i),
                        destinations: List.generate(
                            4,
                            (i) => NavigationDestination(
                                icon: Icon(icons[i]), label: tabs[i]))),
                body: Row(children: [
                  if (wide)
                    NavigationRail(
                        selectedIndex: page,
                        onDestinationSelected: (i) => setState(() => page = i),
                        labelType: NavigationRailLabelType.all,
                        backgroundColor: Colors.white,
                        destinations: List.generate(
                            4,
                            (i) => NavigationRailDestination(
                                icon: Icon(icons[i]), label: Text(tabs[i])))),
                  Expanded(
                      child: SingleChildScrollView(
                          child: Center(
                              child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 1300),
                                  child: Padding(
                                      padding: EdgeInsets.all(
                                          box.maxWidth < 600 ? 18 : 32),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 10),
                                                decoration: BoxDecoration(
                                                    color: s.live
                                                        ? const Color(
                                                            0xffe3efea)
                                                        : const Color(
                                                            0xfffff2d7),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                child: Row(children: [
                                                  Icon(
                                                      s.live
                                                          ? Icons
                                                              .shield_outlined
                                                          : Icons
                                                              .science_outlined,
                                                      size: 18),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                      child: Text(
                                                          s.live
                                                              ? (s.signedIn
                                                                  ? 'Authenticated workspace / ${s.canEdit ? 'Administrator' : 'Staff reader'}'
                                                                  : 'Private workspace / sign in to access records')
                                                              : 'Public preview / Fictional data / Read only',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      12)))
                                                ])),
                                            const SizedBox(height: 25),
                                            Text(tabs[page].toUpperCase(),
                                                style: const TextStyle(
                                                    color: teal,
                                                    fontSize: 11,
                                                    letterSpacing: 2,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            const SizedBox(height: 8),
                                            Text(
                                                [
                                                  'Healthy labs. Ready for learning.',
                                                  'Every asset, in one place.',
                                                  'Keep the next session running.',
                                                  'Spaces built for discovery.'
                                                ][page],
                                                style: TextStyle(
                                                    color: navy,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: box.maxWidth < 600
                                                        ? 29
                                                        : 39,
                                                    height: 1.15)),
                                            const SizedBox(height: 12),
                                            Text(
                                                [
                                                  'A clear view of equipment readiness, service schedules and inspection history.',
                                                  'Search by asset tag, workstation, model or operating system.',
                                                  'Nine preventive checks. Traceable records. Clear follow-up.',
                                                  'Explore equipment and maintenance needs across your workspace.'
                                                ][page],
                                                style: const TextStyle(
                                                    color: Color(0xff617780),
                                                    fontSize: 15)),
                                            const SizedBox(height: 25),
                                            if (s.live && !s.signedIn)
                                              empty(
                                                  'Your lab records are private.',
                                                  'Sign in with an authorized staff account to continue.')
                                            else ...[
                                              if (page == 0)
                                                overview(box.maxWidth),
                                              if (page == 1)
                                                assetPage(box.maxWidth),
                                              if (page == 2)
                                                maintenance(box.maxWidth),
                                              if (page == 3)
                                                labPage(box.maxWidth),
                                            ],
                                            const SizedBox(height: 35),
                                            const Text(
                                                'MBH Lab Management / Portfolio rebuild 2026',
                                                style: TextStyle(
                                                    color: Color(0xff71858d),
                                                    fontSize: 11)),
                                            const SizedBox(height: 8),
                                            const Text(
                                                'Based on the original Lab Management application. Public sample records do not represent a university deployment.',
                                                style: TextStyle(
                                                    color: Color(0xff71858d),
                                                    fontSize: 11)),
                                          ]))))))
                ]));
          }));
  Widget empty(String title, String subtitle) => Card(
      child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(children: [
            const Icon(Icons.search_off, size: 35, color: teal),
            const SizedBox(height: 15),
            Text(title,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
            Text(subtitle, textAlign: TextAlign.center)
          ])));
  Widget heading(String title, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Wrap(
          spacing: 20,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: navy)),
            if (trailing != null) trailing
          ]));
  Widget pill(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: text == 'Ready'
              ? const Color(0xffdcf0e5)
              : text == 'Attention'
                  ? const Color(0xffffe9da)
                  : const Color(0xffe2eaf4),
          borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11, color: navy, fontWeight: FontWeight.w600)));
  Widget stat(String value, String label, IconData icon, double width) =>
      SizedBox(
          width: width,
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.all(21),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: teal, size: 24),
                        const SizedBox(height: 17),
                        Text(value,
                            style: const TextStyle(
                                fontSize: 35,
                                fontWeight: FontWeight.w600,
                                color: navy)),
                        Text(label,
                            style: const TextStyle(
                                color: Color(0xff617780), fontSize: 12))
                      ]))));
  Widget overview(double width) {
    final usable = width >= 1000 ? width - 160 : width - 50;
    final cardWidth = usable < 600 ? (usable - 20) / 2 : (usable - 80) / 4;
    final ready = s.assets.where((a) => a['status'] == 'Ready').length;
    final due = s.assets.where(s.overdue).toList();
    final issues = s.assets.where((a) => a['status'] != 'Ready').toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        stat('${s.assets.length}', 'Tracked assets', Icons.computer, cardWidth),
        stat('$ready', 'Ready for use', Icons.check_circle_outline, cardWidth),
        stat('${due.length}', 'Overdue inspections', Icons.schedule, cardWidth),
        stat('${s.labs.length}', 'Laboratories', Icons.domain_outlined,
            cardWidth)
      ]),
      heading('Needs attention',
          trailing: TextButton(
              onPressed: () => setState(() => page = 2),
              child: const Text('View maintenance'))),
      if (issues.isEmpty)
        empty('Everything is ready.',
            'No equipment currently requires attention.')
      else
        ...issues.take(4).map(assetTile),
      heading('Upcoming inspections'),
      ...([
        ...s.assets
      ]..sort((a, b) => (a['due'] as String).compareTo(b['due'] as String)))
          .take(4)
          .map(assetTile),
      heading('The preventive maintenance workflow'),
      Wrap(spacing: 12, runSpacing: 12, children: [
        workflow('01', 'Locate', 'Find a lab and asset by its equipment tag.'),
        workflow(
            '02', 'Inspect', 'Review the nine hardware and software checks.'),
        workflow('03', 'Follow up',
            'Record outcomes and plan the next service date.')
      ]),
    ]);
  }

  Widget workflow(String n, String title, String body) => SizedBox(
      width: 300,
      child: Card(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n, style: const TextStyle(color: teal, fontSize: 12)),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    Text(body,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xff617780)))
                  ]))));
  List<Map<String, dynamic>> get filtered => s.assets.where((a) {
        final text =
            '${a['name']} ${a['tag']} ${a['model']} ${a['os']}'.toLowerCase();
        return text.contains(search.toLowerCase().trim()) &&
            (lab == 'All labs' || a['labId'] == lab) &&
            (status == 'All statuses' || a['status'] == status);
      }).toList();
  Widget assetPage(double width) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
            controller: searchController,
            onChanged: (v) => setState(() => search = v),
            decoration: const InputDecoration(
                labelText: 'Search assets or enter asset tag',
                prefixIcon: Icon(Icons.search),
                hintText: 'Try DEMO-PC-003')),
        const SizedBox(height: 14),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
              width: 250,
              child: DropdownButtonFormField<String>(
                  value: lab,
                  decoration: const InputDecoration(labelText: 'Laboratory'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                        value: 'All labs', child: Text('All labs')),
                    ...s.labs.map((l) => DropdownMenuItem(
                        value: l['id'] as String,
                        child: Text(l['name'] as String)))
                  ],
                  onChanged: (v) => setState(() => lab = v!))),
          SizedBox(
              width: 210,
              child: DropdownButtonFormField<String>(
                  value: status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Readiness'),
                  items: ['All statuses', 'Ready', 'Attention', 'In service']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => status = v!))),
          if (s.canEdit)
            FilledButton.icon(
                onPressed: addAsset,
                icon: const Icon(Icons.add),
                label: const Text('Add asset'))
        ]),
        heading('${filtered.length} assets'),
        if (filtered.isEmpty)
          empty('No assets found.', 'Try another tag, lab or readiness filter.')
        else
          ...filtered.map(assetTile),
      ]);
  Widget assetTile(Map<String, dynamic> a) => Card(
      child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => assetDetails(a),
          child: Padding(
              padding: const EdgeInsets.all(17),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xffe5efed),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.desktop_windows_outlined,
                        color: teal)),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(a['name'] as String,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: navy)),
                      Text('${a['tag']} / ${s.labName(a['labId'] as String)}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xff617780))),
                      const SizedBox(height: 8),
                      Wrap(spacing: 10, runSpacing: 7, children: [
                        pill(a['status'] as String),
                        Text(
                            '${s.overdue(a) ? 'Overdue' : 'Next service'}: ${a['due']}',
                            style: TextStyle(
                                fontSize: 11,
                                color: s.overdue(a) ? Colors.deepOrange : teal))
                      ])
                    ])),
                const Icon(Icons.arrow_forward_ios, size: 14, color: teal)
              ]))));
  Widget maintenance(double width) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading('Service queue'),
        if (s.assets
            .where((a) => s.overdue(a) || a['status'] != 'Ready')
            .isEmpty)
          empty('No work waiting.', 'Your service queue is clear.')
        else
          ...s.assets
              .where((a) => s.overdue(a) || a['status'] != 'Ready')
              .map(assetTile),
        heading('Inspection history'),
        if (s.inspections.isEmpty)
          empty(
              'No inspections recorded.', 'Completed checks will appear here.')
        else
          ...([...s.inspections]..sort((a, b) =>
                  (b['date'] as String).compareTo(a['date'] as String)))
              .map((r) => Card(
                  child: ListTile(
                      contentPadding: const EdgeInsets.all(17),
                      leading:
                          const Icon(Icons.fact_check_outlined, color: teal),
                      title: Text(s.assets
                              .where((a) => a['id'] == r['assetId'])
                              .map((a) => a['name'] as String)
                              .firstOrNull ??
                          'Archived asset'),
                      subtitle:
                          Text('${r['date']} / ${r['phase']}\n${r['notes']}'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => inspectionDetails(r)))),
      ]);
  Widget labPage(double width) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading('${s.labs.length} laboratories',
            trailing: s.canEdit
                ? FilledButton.icon(
                    onPressed: addLab,
                    icon: const Icon(Icons.add),
                    label: const Text('Add lab'))
                : null),
        ...s.labs.map((l) {
          final assets = s.assets.where((a) => a['labId'] == l['id']).toList();
          final ready = assets.where((a) => a['status'] == 'Ready').length;
          return Card(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.domain_outlined,
                            color: teal, size: 30),
                        const SizedBox(height: 14),
                        Text(l['name'] as String,
                            style: const TextStyle(
                                fontSize: 23, fontWeight: FontWeight.w700)),
                        Text(l['location'] as String,
                            style: const TextStyle(color: Color(0xff617780))),
                        const SizedBox(height: 18),
                        LinearProgressIndicator(
                            value: assets.isEmpty ? 0 : ready / assets.length,
                            minHeight: 6,
                            color: teal),
                        const SizedBox(height: 12),
                        Text('$ready ready / ${assets.length} tracked assets'),
                        const SizedBox(height: 12),
                        TextButton(
                            onPressed: () {
                              setState(() {
                                lab = l['id'] as String;
                                status = 'All statuses';
                                search = '';
                                searchController.clear();
                                page = 1;
                              });
                            },
                            child: const Text('Explore assets'))
                      ])));
        })
      ]);
  Future<void> showPanel(String title, List<Widget> children,
          {List<Widget>? actions}) =>
      showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: Text(title),
                  content: SizedBox(
                      width: 600,
                      child: SingleChildScrollView(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: children))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close')),
                    ...?actions
                  ]));
  void assetDetails(Map<String, dynamic> a) {
    showPanel(
        a['name'] as String,
        [
          pill(a['status'] as String),
          const SizedBox(height: 16),
          Text(
              'Asset tag: ${a['tag']}\nMonitor tag: ${a['monitorTag']}\nLab: ${s.labName(a['labId'] as String)}\nModel: ${a['model']}\nOperating system: ${a['os']}\nNext service: ${a['due']}',
              style: const TextStyle(height: 1.9)),
          const SizedBox(height: 20),
          const Text('Inspection timeline',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          if (s.history(a['id'] as String).isEmpty)
            const Text('No inspection records yet.'),
          ...s.history(a['id'] as String).map((r) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${r['date']} / ${r['phase']}'),
              subtitle: Text(r['notes'] as String),
              onTap: () => inspectionDetails(r)))
        ],
        actions: s.canEdit
            ? [
                FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      recordInspection(a);
                    },
                    child: const Text('Record inspection'))
              ]
            : null);
  }

  void inspectionDetails(Map<String, dynamic> r) =>
      showPanel('Inspection / ${r['date']}', [
        Text('${r['phase']} / ${r['outcome']}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 15),
        ...List.generate(
            inspectionChecks.length,
            (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  Expanded(child: Text(inspectionChecks[i])),
                  pill((r['results'] as List)[i] as String)
                ]))),
        const Divider(),
        Text('Notes: ${r['notes']}\nNext inspection: ${r['nextDue']}'),
        const SizedBox(height: 12),
        const Text(
            'Inspection records are an audit trail. Editing or deletion is not available in the client.',
            style: TextStyle(fontSize: 12, color: teal))
      ]);
  void about() => showPanel('About MBH Lab Management', [
        const Text(
            'A redesigned laboratory equipment and preventive maintenance application, based on the original mobile app by Md Billal Hossain.'),
        const SizedBox(height: 15),
        const Text(
            'The public preview uses fictional labs, asset tags and technician names. It is read only and has no connection to institutional records.'),
        const SizedBox(height: 15),
        const Text(
            'Real deployment requires Firebase Authentication, staff access claims, and the supplied Firestore security rules. Public registration is intentionally unavailable. Passwords and session tokens are never saved in local preferences.'),
      ]);
  Future<void> login() async {
    final email = TextEditingController(), password = TextEditingController();
    String? error;
    bool saving = false;
    await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                    title: const Text('Staff sign in'),
                    content: SizedBox(
                        width: 400,
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              const Text(
                                  'Use an account provisioned by your workspace owner.'),
                              const SizedBox(height: 15),
                              TextField(
                                  controller: email,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                      labelText: 'Email')),
                              const SizedBox(height: 12),
                              TextField(
                                  controller: password,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                      labelText: 'Password')),
                              TextButton(
                                  onPressed: saving
                                      ? null
                                      : () {
                                          Navigator.pop(ctx);
                                          passwordSetup();
                                        },
                                  child: const Text(
                                      "Set or reset your app password")),
                              if (error != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(error!,
                                        style:
                                            const TextStyle(color: Colors.red)))
                            ]))),
                    actions: [
                      TextButton(
                          onPressed: saving ? null : () => Navigator.pop(ctx),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  update(() => saving = true);
                                  try {
                                    await s.authenticate(
                                        email.text, password.text);
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  } catch (_) {
                                    if (ctx.mounted) {
                                      update(() {
                                        error =
                                            'Unable to sign in or access this workspace.';
                                        saving = false;
                                      });
                                    }
                                  }
                                },
                          child: Text(saving ? 'Signing in...' : 'Sign in'))
                    ])));
    email.dispose();
    password.dispose();
  }

  Future<void> passwordSetup() async {
    final email = TextEditingController();
    bool sending = false;
    String? notice;
    await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                    title: const Text('Set or reset app password'),
                    content: SizedBox(
                        width: 420,
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              const Text(
                                  'Use your provisioned staff email. You will set a separate password for this workspace through Firebase’s email link; do not enter your Google account password here.'),
                              const SizedBox(height: 16),
                              TextField(
                                  controller: email,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                      labelText: 'Staff email')),
                              if (notice != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Text(notice!)),
                            ]))),
                    actions: [
                      TextButton(
                          onPressed: sending ? null : () => Navigator.pop(ctx),
                          child: const Text('Close')),
                      FilledButton(
                          onPressed: sending
                              ? null
                              : () async {
                                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(email.text.trim())) {
                                    update(() => notice =
                                        'Enter a valid email address.');
                                    return;
                                  }
                                  update(() => sending = true);
                                  try {
                                    await s.api
                                        .requestPasswordReset(email.text);
                                  } catch (_) {
                                    /* Keep account existence private. */
                                  }
                                  if (ctx.mounted) {
                                    update(() {
                                      sending = false;
                                      notice =
                                          'If this email belongs to a provisioned account, check its inbox for setup instructions. If nothing arrives, check your address and connection or contact your workspace owner.';
                                    });
                                  }
                                },
                          child: Text(sending
                              ? 'Requesting...'
                              : 'Request setup email'))
                    ])));
    email.dispose();
  }

  Future<void> addLab() async {
    final name = TextEditingController(), location = TextEditingController();
    await form('Add laboratory', [name, location], ['Lab name', 'Location'],
        () => s.addLab(name.text, location.text));
  }

  Future<void> addAsset() async {
    if (s.labs.isEmpty) {
      message('Add a laboratory first.');
      return;
    }
    final fields = List.generate(6, (_) => TextEditingController());
    fields[5].text = DateTime.now()
        .add(const Duration(days: 30))
        .toIso8601String()
        .substring(0, 10);
    String selected = s.labs.first['id'] as String;
    await form(
        'Add asset',
        fields,
        [
          'Asset tag',
          'Workstation name',
          'Model',
          'Operating system',
          'Monitor tag',
          'Next service (YYYY-MM-DD)'
        ],
        () => s.addAsset({
              'tag': fields[0].text.trim(),
              'name': fields[1].text.trim(),
              'model': fields[2].text.trim(),
              'os': fields[3].text.trim(),
              'monitorTag': fields[4].text.trim(),
              'due': fields[5].text.trim(),
              'labId': selected
            }),
        extra: StatefulBuilder(
            builder: (ctx, update) => DropdownButtonFormField<String>(
                value: selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Laboratory'),
                items: s.labs
                    .map((l) => DropdownMenuItem(
                        value: l['id'] as String,
                        child: Text(l['name'] as String)))
                    .toList(),
                onChanged: (v) => update(() => selected = v!))));
  }

  Future<void> form(String title, List<TextEditingController> controllers,
      List<String> labels, Future<void> Function() save,
      {Widget? extra}) async {
    bool saving = false;
    String? error;
    await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                    title: Text(title),
                    content: SizedBox(
                        width: 500,
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              if (extra != null) extra,
                              ...List.generate(
                                  controllers.length,
                                  (i) => Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: TextField(
                                          controller: controllers[i],
                                          decoration: InputDecoration(
                                              labelText: labels[i])))),
                              if (error != null)
                                Text(error!,
                                    style: const TextStyle(color: Colors.red))
                            ]))),
                    actions: [
                      TextButton(
                          onPressed: saving ? null : () => Navigator.pop(ctx),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  update(() => saving = true);
                                  try {
                                    await save();
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  } catch (_) {
                                    if (ctx.mounted) {
                                      update(() {
                                        error =
                                            'Check all fields, access and connection. No changes confirmed.';
                                        saving = false;
                                      });
                                    }
                                  }
                                },
                          child: Text(saving ? 'Saving...' : 'Save'))
                    ])));
    for (final c in controllers) {
      c.dispose();
    }
  }

  Future<void> recordInspection(Map<String, dynamic> a) async {
    final results = List.filled(9, 'Not checked');
    final notes = TextEditingController(),
        due = TextEditingController(
            text: DateTime.now()
                .add(const Duration(days: 90))
                .toIso8601String()
                .substring(0, 10));
    String phase = 'Routine';
    bool saving = false;
    String? error;
    await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                    title: Text('Inspect ${a['tag']}'),
                    content: SizedBox(
                        width: 650,
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              const Text(
                                  'Record the actual result for every check. An issue marks the asset as needing attention.'),
                              const SizedBox(height: 15),
                              DropdownButtonFormField<String>(
                                  value: phase,
                                  isExpanded: true,
                                  decoration:
                                      const InputDecoration(labelText: 'Phase'),
                                  items: ['Routine', 'Follow-up', 'Annual']
                                      .map((v) => DropdownMenuItem(
                                          value: v, child: Text(v)))
                                      .toList(),
                                  onChanged: (v) => update(() => phase = v!)),
                              ...List.generate(
                                  9,
                                  (i) => Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: DropdownButtonFormField<String>(
                                          value: results[i],
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                              labelText: inspectionChecks[i]),
                                          items: [
                                            'Not checked',
                                            'Pass',
                                            'Issue',
                                            'Not applicable'
                                          ]
                                              .map((v) => DropdownMenuItem(
                                                  value: v, child: Text(v)))
                                              .toList(),
                                          onChanged: (v) =>
                                              update(() => results[i] = v!)))),
                              const SizedBox(height: 15),
                              TextField(
                                  controller: notes,
                                  maxLines: 3,
                                  maxLength: 2000,
                                  decoration: const InputDecoration(
                                      labelText:
                                          'Findings and follow-up notes')),
                              const SizedBox(height: 15),
                              TextField(
                                  controller: due,
                                  decoration: const InputDecoration(
                                      labelText: 'Next service (YYYY-MM-DD)')),
                              if (error != null)
                                Text(error!,
                                    style: const TextStyle(color: Colors.red))
                            ]))),
                    actions: [
                      TextButton(
                          onPressed: saving ? null : () => Navigator.pop(ctx),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  update(() => saving = true);
                                  try {
                                    await s.recordInspection(a, results,
                                        notes.text, phase, due.text);
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  } catch (_) {
                                    if (ctx.mounted) {
                                      update(() {
                                        saving = false;
                                        error =
                                            'Complete every check, use a valid future date, and verify your access.';
                                      });
                                    }
                                  }
                                },
                          child: Text(
                              saving ? 'Saving...' : 'Complete inspection'))
                    ])));
    notes.dispose();
    due.dispose();
  }
}
