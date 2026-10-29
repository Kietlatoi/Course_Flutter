import 'package:cupertino_ui/cupertino_ui.dart';

import 'contact_groups.dart';
import 'contacts.dart';

const largeScreenMinWidth = 600;

class AdaptiveLayout extends StatefulWidget {
  const AdaptiveLayout({super.key});

  @override
  State<AdaptiveLayout> createState() => _AdaptiveLayoutState();
}

class _AdaptiveLayoutState extends State<AdaptiveLayout> {
  int selectedListId = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > largeScreenMinWidth) {
          return _buildLargeScreenLayout();
        }
        return const ContactGroupsPage();
      },
    );
  }

  Widget _buildLargeScreenLayout() {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.extraLightBackgroundGray,
      child: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 320,
              child: ContactGroupsPage(
                selectedListId: selectedListId,
                onListSelected: (group) =>
                    setState(() => selectedListId = group.id),
              ),
            ),
            Container(width: 1, color: CupertinoColors.separator),
            Expanded(
              child: ContactListsPage(
                key: ValueKey(selectedListId),
                listId: selectedListId,
                automaticallyImplyLeading: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
