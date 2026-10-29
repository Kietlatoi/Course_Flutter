import 'package:cupertino_ui/cupertino_ui.dart';

import '../data/contact.dart';
import '../data/contact_group.dart';
import '../main.dart';

class ContactListsPage extends StatefulWidget {
  const ContactListsPage({
    super.key,
    required this.listId,
    this.automaticallyImplyLeading = true,
  });

  final int listId;
  final bool automaticallyImplyLeading;

  @override
  State<ContactListsPage> createState() => _ContactListsPageState();
}

class _ContactListsPageState extends State<ContactListsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: ValueListenableBuilder<List<ContactGroup>>(
        valueListenable: contactGroupsModel.listsNotifier,
        builder: (context, groups, _) {
          final group = contactGroupsModel.findContactList(widget.listId);
          final sections = AlphabetizedContactMap();
          for (final contact in group.contacts) {
            final name = '${contact.firstName} ${contact.lastName}'
                .toLowerCase();
            if (name.contains(_query)) {
              (sections[contact.lastName[0].toUpperCase()] ??= []).add(contact);
            }
          }
          return CustomScrollView(
            primary: false,
            slivers: [
              CupertinoSliverNavigationBar.search(
                largeTitle: Text(group.title),
                automaticallyImplyLeading: widget.automaticallyImplyLeading,
                transitionBetweenRoutes: false,
                searchField: CupertinoSearchTextField(
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                ),
              ),
              if (sections.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      group.contacts.isEmpty
                          ? 'Nhóm này chưa có liên hệ.'
                          : 'Không tìm thấy liên hệ.',
                    ),
                  ),
                )
              else
                SliverList.list(
                  children: [
                    const SizedBox(height: 20),
                    for (final section in sections.entries)
                      ContactListSection(
                        lastInitial: section.key,
                        contacts: section.value,
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class ContactListSection extends StatelessWidget {
  const ContactListSection({
    super.key,
    required this.lastInitial,
    required this.contacts,
  });

  final String lastInitial;
  final List<Contact> contacts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          Text(
            lastInitial,
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          CupertinoListSection(
            backgroundColor: CupertinoColors.systemBackground,
            dividerMargin: 0,
            additionalDividerMargin: 0,
            topMargin: 4,
            children: [
              for (final contact in contacts)
                CupertinoListTile(
                  padding: EdgeInsets.zero,
                  title: Text('${contact.firstName} ${contact.lastName}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
