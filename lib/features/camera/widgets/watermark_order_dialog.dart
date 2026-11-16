
import 'package:material_ui/material_ui.dart';

const List<String> defaultWatermarkOrder = [
  'customText',
  'address',
  'coordinates',
  'altitude',
  'speed',
  'dateTime',
  'compass',
  'label',
  'sequence',
  'accuracy',
  'note',
];

const Map<String, String> watermarkOrderLabels = {
  'customText': 'Texto personalizado',
  'address': 'Dirección',
  'coordinates': 'GPS / Coordenadas',
  'altitude': 'Altitud',
  'speed': 'Velocidad',
  'dateTime': 'Fecha y hora',
  'compass': 'Brújula',
  'label': 'Etiqueta',
  'sequence': 'Número de índice',
  'accuracy': 'Precisión GPS',
  'note': 'Nota',
};

Future<List<String>?> showWatermarkOrderDialog({
  required BuildContext context,
  required List<String> currentOrder,
}) async {
  final order = <String>[
    ...currentOrder.where(
      (item) => watermarkOrderLabels.containsKey(item),
    ),
  ];

  for (final item in defaultWatermarkOrder) {
    if (!order.contains(item)) {
      order.add(item);
    }
  }

  return showDialog<List<String>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          void restoreOrder() {
            setDialogState(() {
              order
                ..clear()
                ..addAll(defaultWatermarkOrder);
            });
          }

          return AlertDialog(
            title: const Text('Ordenar elementos'),
            content: SizedBox(
              width: double.maxFinite,
              height: 440,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mantén presionado el controlador y arrastra '
                    'los elementos para cambiar su posición.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: order.length,
                      buildDefaultDragHandles: false,
                      onReorderItem: (oldIndex, newIndex) {
                        setDialogState(() {
                          final item = order.removeAt(oldIndex);
                          order.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final item = order[index];

                        return Container(
                          key: ValueKey(item),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.25),
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              watermarkOrderLabels[item] ?? item,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: ReorderableDragStartListener(
                              index: index,
                              child: const Icon(
                                Icons.drag_handle,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: restoreOrder,
                child: const Text('Restaurar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    List<String>.from(order),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    },
  );
}
