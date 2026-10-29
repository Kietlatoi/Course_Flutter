import 'package:flutter_test/flutter_test.dart';
import 'package:rolodex/data/contact.dart';
import 'package:rolodex/data/contact_group.dart';

void main() {
  test('Seed data contains all contacts and the tutorial groups', () {
    final model = ContactGroupsModel();
    addTearDown(model.dispose);
    expect(model.lists.map((group) => group.label), [
      'All iPhone',
      'Friends',
      'Work',
    ]);
    expect(model.findContactList(0).contacts.toSet(), allContacts);
    expect(allContacts.length, 51);
    expect(allContacts.map((contact) => contact.id).toSet().length, 51);
    expect(model.findContactList(0).permanent, isTrue);
    expect(model.findContactList(1).contacts.single, danielHiggins);
    expect(model.findContactList(2).contacts, isEmpty);
    expect(hankZakroff.middleName, 'M.');
    expect(danielHiggins.suffix, 'Jr.');
  });

  test('Contacts are sorted and grouped by last initial', () {
    final group = ContactGroup(
      id: 10,
      label: 'Example',
      contacts: [
        Contact(id: 5, firstName: 'Amy', middleName: 'Z.', lastName: 'Brown'),
        Contact(id: 4, firstName: 'Amy', middleName: 'A.', lastName: 'Brown'),
        Contact(id: 3, firstName: 'Amy', lastName: 'Brown'),
        Contact(id: 2, firstName: 'Amy', lastName: 'Brown'),
        Contact(id: 1, firstName: 'Zoe', lastName: 'Adams'),
        Contact(id: 6, firstName: 'Ben', lastName: 'Brown'),
      ],
    );
    expect(group.title, 'Example');
    expect(group.contacts.map((contact) => contact.id), [1, 2, 3, 4, 5, 6]);
    expect(group.alphabetizedContacts.keys, ['A', 'B']);
    expect(group.alphabetizedContacts['B']!.length, 5);
  });

  test('The notifier announces a replacement group list', () {
    final model = ContactGroupsModel();
    addTearDown(model.dispose);
    var notifications = 0;
    model.listsNotifier.addListener(() => notifications++);
    model.listsNotifier.value = [
      ...model.lists,
      ContactGroup(id: 3, label: 'Family'),
    ];
    expect(notifications, 1);
    expect(model.findContactList(3).label, 'Family');
  });
}
