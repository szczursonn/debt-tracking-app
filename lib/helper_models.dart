enum HistoryListItemType {debt, payment}

class HistoryListItem {
  HistoryListItem({required this.id, required this.date, required this.type});

  int id;
  DateTime date;
  HistoryListItemType type;
}