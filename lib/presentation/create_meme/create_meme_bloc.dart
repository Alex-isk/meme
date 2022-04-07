import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_selection.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';
import 'package:collection/collection.dart';

class CreateMemeBloc {
  final memeTextSubject = BehaviorSubject<List<MemeText>>.seeded(<MemeText>[]);

  /// добавляем Stream<List<MemeText>> см ниже
  final selectedMemeTextSubject = BehaviorSubject<MemeText?>.seeded(null);

  /// выделеный текст/// может быть или не быть - ставим ? и null
  /// добавляем Stream<MemeText?>  см ниже

  // void addNewText() {
  //   memeTextSubject.add(memeTextSubject.value..add(MemeText.create()));
  // }
  /// метод который добавит текст на холсте при нажатии на кнопку
  /// берем предыдущий текст memeTextSubject.add и после этого добавить в него новый текст
  /// .. - каскадный оператор позволяет вызвать метод, который не возвращает ничего,
  /// но при этом позволяет вернуть,то что получилось в результате
  /// получается - берет список memeTextSubject.value..add
  /// добавляет новый эллемент ..add(MemeText.create()) и возвращает обратно
  /// можно сделать используя спредоператор ... 3точки упрощающий вставку нескольких значений
  /// см ниже

  void addNewText() {
    final newMemeText = MemeText.create();
    memeTextSubject.add([...memeTextSubject.value, newMemeText]);
    selectedMemeTextSubject.add(newMemeText);
  }

  void changeMemeText(final String id, final String text) {
    final copiedList = [...memeTextSubject.value];

    /// новый лист на основании старого листа
    final index = copiedList.indexWhere((memeText) => memeText.id == id);

    /// найдем индекс эллемента который равен id который мы получили
    if (index == -1) {
      /// если индекс равен -1 то ничего ненашли - просто возвращаем
      return;
    }
    copiedList.removeAt(index);

    ///  в определенном индексе удаляем объект который былсо старым текстом и добавляем в этот индекс новый текст MemeText
    copiedList.insert(index, MemeText(id: id, text: text));
    memeTextSubject.add(copiedList);

    /// возвращаем memeTextSubject в новый список с измененным текстом
  }

  void selectMemeText(final String id) {
    final foundMemeText =
        memeTextSubject.value.firstWhereOrNull((memeText) => memeText.id == id);
    selectedMemeTextSubject.add(foundMemeText);
  }

  /// берем текущий список с мемами memeTextSubject.value.- подкл метод .firstWhereOrNull
  /// который позволяет найти первый эллемент по заданным критериям memeText.id == id
  /// А selectedMemeTextSubject.add будет этот текст foundMemeText добавлять

  void deselectMemeText() {
    selectedMemeTextSubject.add(null);
  }

  Stream<List<MemeText>> observeMemeText() => memeTextSubject
      .distinct((prev, next) => ListEquality().equals(prev, next));

  /// .distinct() оставляет только не повторяющиеся подряд значения
  /// ListEquality().equals(prev, next)) дает отличающиеся коллекции

  Stream<MemeText?> observeSelectedMemeText() =>
      selectedMemeTextSubject.distinct();

  /// ДЗ-6 возвращает лист с MemeTextWithSelection / название стрима observeMemeTextWithSelection()
  Stream<List<MemeTextWithSelection>> observeMemeTextWithSelection() {
    return Rx.combineLatest2<List<MemeText>, MemeText?, List<MemeTextWithSelection>>(
      observeMemeText(),
      observeSelectedMemeText(),
      (memeTexts, selectedMemeText) {
        ///   (a=memeTexts, b=selectedMemeText) {
        return memeTexts.map((memeText) {
          return MemeTextWithSelection(memeText: memeText, selected: memeText.id == selectedMemeText?.id);
        }).toList();
      }
    );
  }

  /// список List<MemeText>, выделеный текст MemeText?, возвращаем MemeTextWithSelection
  void dispose() {
    memeTextSubject.close();
    selectedMemeTextSubject.close();
  }
}


