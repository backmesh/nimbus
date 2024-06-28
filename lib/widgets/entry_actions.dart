import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import '../user_store.dart';

class EntryActions extends StatefulWidget {
  final String entryKey;
  final Entry entry;
  const EntryActions(this.entryKey, this.entry);

  @override
  _EntryActionsState createState() => _EntryActionsState();
}

class _EntryActionsState extends State<EntryActions> {
  late DateTime date;

  void initState() {
    super.initState();
    date = widget.entry.date;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      InkWell(
          onTap: () async {
            final start = date.subtract(Duration(days: 180));
            final end = DateTime.now();
            DateTime? newDate = await showDatePicker(
                context: context,
                confirmText: 'Change entry date',
                initialEntryMode: DatePickerEntryMode.calendarOnly,
                firstDate: start,
                initialDate: date,
                currentDate: date,
                lastDate: end);
            if (newDate == null) return;
            setState(() {
              date = newDate;
            });
            await UserStore.instance.saveEntry(
                widget.entryKey,
                Entry(
                    date: newDate,
                    doc: widget.entry.doc,
                    tagIds: widget.entry.tagIds));
            await Posthog().capture(eventName: 'DateChangeEntry', properties: {
              'hasAudio': widget.entry.hasAudio(),
            });
          },
          child: Row(
            children: [
              Icon(
                Icons.calendar_month,
                size: 20,
              ),
              const SizedBox(width: 6.0),
              Text(
                localizations.formatShortDate(date),
                style: TextStyle(fontSize: 16),
              )
            ],
          )),
      InkWell(
          onTap: () async {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Delete entry?'),
                  content: const Text(
                      '''Are you sure you want to delete this entry?'''),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: const Text(
                        'Delete',
                        selectionColor: Colors.red,
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () async {
                        try {
                          await UserStore.instance
                              .deleteEntry(widget.entryKey, widget.entry);
                          Navigator.of(context).pop('deleted');
                          Navigator.of(context).pop('deleted');
                          await Posthog()
                              .capture(eventName: 'DeleteEntry', properties: {
                            'hasAudio': widget.entry.hasAudio(),
                          });
                        } catch (e) {
                          // TODO Handle exceptions
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 20,
              ),
              const SizedBox(width: 5.0),
              Text(
                'Delete',
                style: TextStyle(fontSize: 16),
              )
            ],
          ))
    ]);
  }
}
