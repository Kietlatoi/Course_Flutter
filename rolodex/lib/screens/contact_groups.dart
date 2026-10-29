import 'package:cupertino_ui/cupertino_ui.dart';

import '../data/contact_group.dart';
import '../main.dart';
import 'contacts.dart';

class ContactGroupsPage extends StatelessWidget {
  const ContactGroupsPage({
    super.key,
    this.selectedListId,
    this.onListSelected,
  });

  final int? selectedListId;
  final ValueChanged<ContactGroup>? onListSelected;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.extraLightBackgroundGray,
      child: CustomScrollView(
        primary: false,
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Lists'),
            transitionBetweenRoutes: false,
          ),
          SliverToBoxAdapter(
            child: ValueListenableBuilder<List<ContactGroup>>(
              valueListenable: contactGroupsModel.listsNotifier,
              builder: (context, groups, _) {
                return CupertinoListSection.insetGrouped(
                  header: const Text('iPhone'),
                  children: [
                    for (final group in groups)
                      CupertinoListTile(
                        leading: Icon(
                          group.id == 0
                              ? CupertinoIcons.group
                              : CupertinoIcons.person_2,
                          color: CupertinoColors.activeBlue,
                        ),
                        title: Text(group.label),
                        backgroundColor: selectedListId == group.id
                            ? CupertinoColors.tertiarySystemFill
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${group.contacts.length}',
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.forward,
                              color: CupertinoColors.systemGrey3,
                              size: 18,
                            ),
                          ],
                        ),
                        onTap: () {
                          if (onListSelected != null) {
                            onListSelected!(group);
                          } else {
                            Navigator.of(context).push(
                              CupertinoPageRoute<void>(
                                title: group.title,
                                builder: (context) =>
                                    ContactListsPage(listId: group.id),
                              ),
                            );
                          }
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
