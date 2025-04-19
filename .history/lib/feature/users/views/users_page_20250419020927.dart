import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:todoApp/feature/shared/utils/platform.dart';
import 'package:todoApp/feature/shared/utils/styles/app_color.dart';
import 'package:todoApp/feature/shared/utils/styles/app_text_style.dart';
import 'package:todoApp/feature/shared/widgets/shared_sliver_app_bar.dart';
import 'package:todoApp/feature/users/models/user_model.dart';
import 'package:todoApp/feature/users/providers/users_notifier_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

@RoutePage()
class UsersWrapperPage extends StatelessWidget {
  const UsersWrapperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return getPlatformSpecificPage(const UsersPage(title: 'Riverpod Demo'),
        const IOSUsersPage(title: 'Riverpod Demo(ios)'));
  }
}

class UsersPage extends StatefulHookConsumerWidget {
  final String title;

  const UsersPage({
    required this.title,
    super.key,
  });

  @override
  ConsumerState<UsersPage> createState() => _UsersPage();
}

class _UsersPage extends ConsumerState<UsersPage> {
  final _searchController = TextEditingController();
  bool isSearching = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SharedSliverAppBar(
              title: widget.title,
            ),
            const SliverPadding(padding: EdgeInsets.symmetric(vertical: 8)),
            _buildSearchView(),
            _buildListRootView(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchView() {
    final isSearchingNotifier = useState(false);
    return SliverPadding(
      padding: const EdgeInsets.all(8.0),
      sliver: SliverToBoxAdapter(
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
              labelText: 'Search',
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _clearSearch(isSearchingNotifier),
                color: Colors.grey,
              )),
          onChanged: (value) {
            isSearchingNotifier.value = true;
            // TODO search using notifier provider
          },
        ),
      ),
    );
  }

  void _clearSearch(ValueNotifier<bool> isSearchingNotifier) {
    _searchController.clear();
    isSearchingNotifier.value = false;
  }

  Widget _buildListRootView() {
    final usersListAsync = ref.watch(usersNotifierProviderProvider);

    return switch (usersListAsync) {
      AsyncError(:final error) => SliverToBoxAdapter(
          child: SliverToBoxAdapter(child: Text('Error $error'))),
      AsyncData(:final value) => _buildListView(value),
      _ => const SliverToBoxAdapter(child: Center(child: Text('Loading...'))),
    };
  }

  Widget _buildListView(List<UserModel> modelList) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final entry = modelList[index];
          return _buildListRowView(entry);
        },
        childCount: modelList.length,
      ),
    );
  }

  Widget _buildListRowView(UserModel model) {
    return ListTile(
      title: Text(
        model.firstName.toString(),
        style: AppTextStyle.labelLarge,
      ),
      subtitle: Text(
        'desc',
        style:
            AppTextStyle.bodySmall.copyWith(color: context.color.textPrimary),
      ),
    );
  }
}

class IOSUsersPage extends StatefulHookConsumerWidget {
  final String title;

  const IOSUsersPage({
    required this.title,
    super.key,
  });

  @override
  ConsumerState<IOSUsersPage> createState() => _IOSUsersPageState();
}

class _IOSUsersPageState extends ConsumerState<IOSUsersPage> {
  final _searchController = TextEditingController();
  bool isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
        // This is equivalent to the AppBar in Material Design
      ),
      child: SafeArea(
        child: CustomScrollView(
          // Using CustomScrollView with slivers for iOS as well
          slivers: [
            // Adding padding instead of SliverAppBar since we're using CupertinoNavigationBar
            const SliverPadding(padding: EdgeInsets.only(top: 8)),
            _buildSearchView(),
            _buildListRootView(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchView() {
    final isSearchingNotifier = useState(false);
    return SliverPadding(
      padding: const EdgeInsets.all(8.0),
      sliver: SliverToBoxAdapter(
        child: CupertinoSearchTextField(
          controller: _searchController,
          placeholder: 'Search',
          onChanged: (value) {
            isSearchingNotifier.value = true;
            // TODO search using notifier provider
          },
          onSuffixTap: () => _clearSearch(isSearchingNotifier),
        ),
      ),
    );
  }

  void _clearSearch(ValueNotifier<bool> isSearchingNotifier) {
    _searchController.clear();
    isSearchingNotifier.value = false;
  }

  Widget _buildListRootView() {
    final usersListAsync = ref.watch(usersNotifierProviderProvider);

    return switch (usersListAsync) {
      AsyncError(:final error) => SliverToBoxAdapter(
          child: Center(
              child: Text('Error $error',
                  style:
                      const TextStyle(color: CupertinoColors.destructiveRed)))),
      AsyncData(:final value) => _buildListView(value),
      _ => const SliverToBoxAdapter(
          child: Center(child: CupertinoActivityIndicator())),
    };
  }

  Widget _buildListView(List<UserModel> modelList) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final entry = modelList[index];
          return _buildListRowView(entry);
        },
        childCount: modelList.length,
      ),
    );
  }

  Widget _buildListRowView(UserModel model) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.5,
          ),
        ),
      ),
      child: CupertinoListTile(
        title: Text(
          model.firstName.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'desc',
          style: const TextStyle(
            fontSize: 14,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
        trailing: const CupertinoListTileChevron(),
      ),
    );
  }
}
