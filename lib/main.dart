import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MaskedInboxApp());
}

const _apiKeyStorageKey = 'firefox_relay_api_key';
const _sortPreferenceKey = 'mask_sort_order';

class MaskedInboxApp extends StatelessWidget {
  const MaskedInboxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masked Inbox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}

class AppTheme {
  static const orange100 = Color(0xffff9e00);
  static const orange200 = Color(0xffff9100);
  static const orange300 = Color(0xffff8500);
  static const orange400 = Color(0xffff7900);
  static const orange500 = Color(0xffff6d00);

  static const purple100 = Color(0xff9d4edd);
  static const purple200 = Color(0xff7b2cbf);
  static const purple300 = Color(0xff5a189a);
  static const purple400 = Color(0xff3c096c);
  static const purple500 = Color(0xff240046);

  static const neutral000 = Color(0xffffffff);
  static const neutral050 = Color(0xfff9f8fc);
  static const neutral100 = Color(0xfff0edf6);
  static const neutral200 = Color(0xffe0d9eb);
  static const neutral300 = Color(0xffb8adcb);
  static const neutral400 = Color(0xff887a9e);
  static const neutral500 = Color(0xff5d5073);
  static const neutral600 = Color(0xff382e47);
  static const neutral700 = Color(0xff221a2e);
  static const neutral800 = Color(0xff15101e);
  static const neutral900 = Color(0xff0d0b12);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: purple300,
      brightness: Brightness.light,
      primary: purple400,
      secondary: orange500,
      surface: neutral050,
      onSurface: neutral600,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: neutral050,
      appBarTheme: const AppBarTheme(
        backgroundColor: neutral050,
        foregroundColor: neutral600,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: neutral000,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: neutral200),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: orange500,
          foregroundColor: neutral000,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: purple300,
          side: const BorderSide(color: neutral300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutral000,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: orange200, width: 2),
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _storage = const FlutterSecureStorage();
  late Future<String?> _apiKeyFuture;

  @override
  void initState() {
    super.initState();
    _apiKeyFuture = _storage.read(key: _apiKeyStorageKey);
  }

  Future<void> _saveApiKey(String apiKey) async {
    await _storage.write(key: _apiKeyStorageKey, value: apiKey);
    setState(() {
      _apiKeyFuture = Future.value(apiKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _apiKeyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        final apiKey = snapshot.data;
        if (apiKey == null || apiKey.isEmpty) {
          return ApiKeyScreen(onSaved: _saveApiKey);
        }

        return HomeScreen(
          apiKey: apiKey,
          onApiKeyChanged: _saveApiKey,
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({required this.onSaved, super.key});

  final Future<void> Function(String apiKey) onSaved;

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    await widget.onSaved(_controller.text.trim());
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _openRelaySettings() async {
    final uri = Uri.parse('https://relay.firefox.com/accounts/profile/');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/api_key_guide.gif',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 180,
                          color: AppTheme.neutral100,
                          alignment: Alignment.center,
                          child: const Icon(Icons.key, size: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Connect Firefox Relay',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.neutral600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Paste your Relay API key once. It will be stored securely on this device.',
                      style: TextStyle(color: AppTheme.neutral500),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _controller,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'API key',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your Firefox Relay API key';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_open),
                      label: const Text('Save key'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _openRelaySettings,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Relay account settings'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.purple500,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.alternate_email, color: AppTheme.orange100),
        ),
        const SizedBox(width: 12),
        Text(
          'Masked Inbox',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.purple500,
              ),
        ),
      ],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.apiKey,
    required this.onApiKeyChanged,
    super.key,
  });

  final String apiKey;
  final Future<void> Function(String apiKey) onApiKeyChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late RelayApiClient _apiClient;
  late Future<HomeData> _homeData;
  SortOrder _sortOrder = SortOrder.createdNewest;

  @override
  void initState() {
    super.initState();
    _apiClient = RelayApiClient(apiKey: widget.apiKey);
    _homeData = _loadHome();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apiKey != widget.apiKey) {
      _apiClient = RelayApiClient(apiKey: widget.apiKey);
      _refresh();
    }
  }

  Future<HomeData> _loadHome() async {
    final prefs = await SharedPreferences.getInstance();
    _sortOrder = SortOrder.values.firstWhere(
      (order) => order.name == prefs.getString(_sortPreferenceKey),
      orElse: () => SortOrder.createdNewest,
    );

    final results = await Future.wait([
      _apiClient.fetchProfile(),
      _apiClient.fetchMasks(),
    ]);

    return HomeData(
      profile: results[0] as RelayProfile,
      masks: _sorted(results[1] as List<EmailMask>),
    );
  }

  List<EmailMask> _sorted(List<EmailMask> masks) {
    final sorted = [...masks];
    switch (_sortOrder) {
      case SortOrder.createdNewest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOrder.alphabetical:
        sorted.sort((a, b) => a.fullAddress.compareTo(b.fullAddress));
    }
    return sorted;
  }

  void _refresh() {
    setState(() => _homeData = _loadHome());
  }

  Future<void> _refreshAndWait() async {
    final nextHomeData = _loadHome();
    setState(() => _homeData = nextHomeData);
    await nextHomeData;
  }

  Future<void> _setSortOrder(SortOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortPreferenceKey, order.name);
    setState(() {
      _sortOrder = order;
      _homeData = _homeData.then(
        (data) => data.copyWith(masks: _sorted(data.masks)),
      );
    });
  }

  Future<void> _openCreateMask(HomeData data) async {
    final created = await Navigator.of(context).push<EmailMask>(
      MaterialPageRoute(
        builder: (_) => CreateMaskScreen(
          apiClient: _apiClient,
          profile: data.profile,
        ),
      ),
    );

    if (created != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copied ${created.fullAddress}')),
        );
      }
      _refresh();
    }
  }

  Future<void> _openSettings() async {
    final newKey = await showDialog<String>(
      context: context,
      builder: (_) => ChangeApiKeyDialog(currentKey: widget.apiKey),
    );

    if (newKey != null && newKey.trim().isNotEmpty) {
      await widget.onApiKeyChanged(newKey.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
      future: _homeData,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Masked Inbox'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Change API key',
                onPressed: _openSettings,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: snapshot.connectionState != ConnectionState.done
                ? const Center(child: CircularProgressIndicator())
                : snapshot.hasError
                    ? ErrorState(
                        message: snapshot.error.toString(),
                        onRetry: _refresh,
                      )
                    : MaskListView(
                        data: data!,
                        sortOrder: _sortOrder,
                        onSortChanged: _setSortOrder,
                        onCreate: () => _openCreateMask(data),
                        onRefresh: _refreshAndWait,
                      ),
          ),
        );
      },
    );
  }
}

class MaskListView extends StatelessWidget {
  const MaskListView({
    required this.data,
    required this.sortOrder,
    required this.onSortChanged,
    required this.onCreate,
    required this.onRefresh,
    super.key,
  });

  final HomeData data;
  final SortOrder sortOrder;
  final ValueChanged<SortOrder> onSortChanged;
  final VoidCallback onCreate;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _ProfileSummary(profile: data.profile),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('New mask'),
                ),
              ),
              const SizedBox(width: 12),
              SegmentedButton<SortOrder>(
                segments: const [
                  ButtonSegment(
                    value: SortOrder.createdNewest,
                    icon: Icon(Icons.schedule),
                    tooltip: 'Sort by date created',
                  ),
                  ButtonSegment(
                    value: SortOrder.alphabetical,
                    icon: Icon(Icons.sort_by_alpha),
                    tooltip: 'Sort alphabetically',
                  ),
                ],
                selected: {sortOrder},
                onSelectionChanged: (selection) => onSortChanged(selection.first),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.masks.isEmpty)
            const EmptyState()
          else
            ...data.masks.map((mask) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MaskRow(mask: mask),
                )),
        ],
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile});

  final RelayProfile profile;

  @override
  Widget build(BuildContext context) {
    final premiumText = profile.hasPremium ? 'Premium' : 'Free';
    final subdomainText = profile.subdomain == null ? 'No custom domain' : '${profile.subdomain}.mozmail.com';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.verified_user_outlined, color: AppTheme.purple200),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$premiumText Relay account',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    subdomainText,
                    style: const TextStyle(color: AppTheme.neutral500),
                  ),
                ],
              ),
            ),
            Text(
              '${profile.totalMasks}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.purple300,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class MaskRow extends StatelessWidget {
  const MaskRow({required this.mask, super.key});

  final EmailMask mask;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: mask.fullAddress));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied ${mask.fullAddress}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final created = DateFormat.yMMMd().format(mask.createdAt.toLocal());

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: mask.isCustom ? AppTheme.purple300 : AppTheme.orange100,
          foregroundColor: AppTheme.neutral000,
          child: Icon(mask.isCustom ? Icons.edit_outlined : Icons.shuffle),
        ),
        title: Text(
          mask.fullAddress,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${mask.kindLabel} - Created $created'),
        trailing: IconButton(
          tooltip: 'Copy email mask',
          onPressed: () => _copy(context),
          icon: const Icon(Icons.copy),
        ),
      ),
    );
  }
}

class CreateMaskScreen extends StatefulWidget {
  const CreateMaskScreen({
    required this.apiClient,
    required this.profile,
    super.key,
  });

  final RelayApiClient apiClient;
  final RelayProfile profile;

  @override
  State<CreateMaskScreen> createState() => _CreateMaskScreenState();
}

class _CreateMaskScreenState extends State<CreateMaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _customController = TextEditingController();
  MaskKind _kind = MaskKind.random;
  var _blockEmails = false;
  var _saving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _customController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final created = _kind == MaskKind.random
          ? await widget.apiClient.createRandomMask(
              description: _descriptionController.text.trim(),
              blockListEmails: _blockEmails,
            )
          : await widget.apiClient.createCustomMask(
              address: _customController.text.trim(),
              description: _descriptionController.text.trim(),
              blockListEmails: _blockEmails,
            );

      await Clipboard.setData(ClipboardData(text: created.fullAddress));
      if (mounted) Navigator.of(context).pop(created);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreateCustom = widget.profile.hasPremium && widget.profile.subdomain != null;
    if (!canCreateCustom && _kind == MaskKind.custom) {
      _kind = MaskKind.random;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create mask')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<MaskKind>(
                segments: [
                  const ButtonSegment(
                    value: MaskKind.random,
                    icon: Icon(Icons.shuffle),
                    label: Text('Random'),
                  ),
                  ButtonSegment(
                    value: MaskKind.custom,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Custom'),
                    enabled: canCreateCustom,
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (selection) => setState(() => _kind = selection.first),
              ),
              if (!canCreateCustom) ...[
                const SizedBox(height: 12),
                const _PremiumNotice(),
              ],
              const SizedBox(height: 18),
              if (_kind == MaskKind.custom)
                TextFormField(
                  controller: _customController,
                  decoration: InputDecoration(
                    labelText: 'Custom mask',
                    suffixText: '.${widget.profile.subdomain}.mozmail.com',
                    prefixIcon: const Icon(Icons.alternate_email),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (_kind != MaskKind.custom) return null;
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return 'Enter a custom mask name';
                    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(trimmed)) {
                      return 'Use letters, numbers, dots, underscores, or hyphens';
                    }
                    return null;
                  },
                ),
              if (_kind == MaskKind.custom) const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLength: 64,
              ),
              SwitchListTile(
                value: _blockEmails,
                onChanged: (value) => setState(() => _blockEmails = value),
                title: const Text('Block emails by default'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _saving ? null : _create,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text('Create mask'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumNotice extends StatelessWidget {
  const _PremiumNotice();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, color: AppTheme.purple200),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Custom masks require Firefox Relay premium and an account subdomain.',
                style: TextStyle(color: AppTheme.neutral500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangeApiKeyDialog extends StatefulWidget {
  const ChangeApiKeyDialog({required this.currentKey, super.key});

  final String currentKey;

  @override
  State<ChangeApiKeyDialog> createState() => _ChangeApiKeyDialogState();
}

class _ChangeApiKeyDialogState extends State<ChangeApiKeyDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentKey);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change API key'),
      content: TextField(
        controller: _controller,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'API key'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppTheme.neutral400),
          SizedBox(height: 12),
          Text('No masks yet', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.orange500),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.neutral500),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class RelayApiClient {
  RelayApiClient({
    required this.apiKey,
    http.Client? client,
    Uri? baseUri,
  })  : _client = client ?? http.Client(),
        _baseUri = baseUri ??
            Uri.parse(kIsWeb ? 'http://localhost:8787' : 'https://relay.firefox.com');

  final String apiKey;
  final http.Client _client;
  final Uri _baseUri;

  Map<String, String> get _headers => {
        'Authorization': 'Token $apiKey',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Future<RelayProfile> fetchProfile() async {
    final json = await _getList('/api/v1/profiles/');
    if (json.isEmpty) throw RelayApiException('No Relay profile was returned.');
    return RelayProfile.fromJson(json.first);
  }

  Future<List<EmailMask>> fetchMasks() async {
    final randomMasks = await _getList('/api/v1/relayaddresses/');
    final customMasks = await _getList('/api/v1/domainaddresses/');
    return [
      ...randomMasks.map((item) => EmailMask.fromJson(item, MaskKind.random)),
      ...customMasks.map((item) => EmailMask.fromJson(item, MaskKind.custom)),
    ];
  }

  Future<EmailMask> createRandomMask({
    required String description,
    required bool blockListEmails,
  }) async {
    final body = {
      if (description.isNotEmpty) 'description': description,
      'block_list_emails': blockListEmails,
    };
    final json = await _post('/api/v1/relayaddresses/', body);
    return EmailMask.fromJson(json, MaskKind.random);
  }

  Future<EmailMask> createCustomMask({
    required String address,
    required String description,
    required bool blockListEmails,
  }) async {
    final body = {
      'address': address,
      if (description.isNotEmpty) 'description': description,
      'block_list_emails': blockListEmails,
    };
    final json = await _post('/api/v1/domainaddresses/', body);
    return EmailMask.fromJson(json, MaskKind.custom);
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await _client.get(_baseUri.resolve(path), headers: _headers);
    final decoded = _decodeResponse(response);
    if (decoded is! List) {
      throw RelayApiException('Relay returned an unexpected response.');
    }
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await _client.post(
      _baseUri.resolve(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw RelayApiException('Relay returned an unexpected response.');
    }
    return decoded;
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RelayApiException('Relay request failed with status ${response.statusCode}.');
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }
}

class RelayApiException implements Exception {
  RelayApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HomeData {
  const HomeData({
    required this.profile,
    required this.masks,
  });

  final RelayProfile profile;
  final List<EmailMask> masks;

  HomeData copyWith({RelayProfile? profile, List<EmailMask>? masks}) {
    return HomeData(
      profile: profile ?? this.profile,
      masks: masks ?? this.masks,
    );
  }
}

class RelayProfile {
  const RelayProfile({
    required this.hasPremium,
    required this.totalMasks,
    this.subdomain,
  });

  final bool hasPremium;
  final int totalMasks;
  final String? subdomain;

  factory RelayProfile.fromJson(Map<String, dynamic> json) {
    return RelayProfile(
      hasPremium: json['has_premium'] as bool? ?? false,
      totalMasks: json['total_masks'] as int? ?? 0,
      subdomain: json['subdomain'] as String?,
    );
  }
}

class EmailMask {
  const EmailMask({
    required this.id,
    required this.fullAddress,
    required this.createdAt,
    required this.kind,
    this.enabled = true,
  });

  final int id;
  final String fullAddress;
  final DateTime createdAt;
  final MaskKind kind;
  final bool enabled;

  bool get isCustom => kind == MaskKind.custom;
  String get kindLabel => isCustom ? 'Custom' : 'Random';

  factory EmailMask.fromJson(Map<String, dynamic> json, MaskKind fallbackKind) {
    final rawKind = json['mask_type'] as String?;
    final kind = rawKind == 'custom'
        ? MaskKind.custom
        : rawKind == 'random'
            ? MaskKind.random
            : fallbackKind;

    return EmailMask(
      id: json['id'] as int,
      fullAddress: json['full_address'] as String? ?? json['address'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      enabled: json['enabled'] as bool? ?? true,
      kind: kind,
    );
  }
}

enum MaskKind { random, custom }

enum SortOrder { createdNewest, alphabetical }
