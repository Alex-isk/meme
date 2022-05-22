import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/position.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:memogenerator/domain/interactors/save_meme_interactor.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_selection.dart';
import 'package:path_provider/path_provider.dart';
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
  final memeTextOffsetsSubject =
      BehaviorSubject<List<MemeTextOffset>>.seeded(<MemeTextOffset>[]);

  /// отсл изменение сдвига - позиции (memeTextOffsetsSubject)
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

  final newMemeTextOffsetSubject =
      BehaviorSubject<MemeTextOffset?>.seeded(null);

  /// ImagePicker  добавляем логику чтобы был subject в котором сохраняется и находится текущий путь до файла
  final memePathSubject = BehaviorSubject<String?>.seeded(null);

  /// ImagePicker

  StreamSubscription<MemeTextOffset?>? newMemeTextOffsetSubscription;
  StreamSubscription<bool>? saveMemeSubscription;
  StreamSubscription<Meme?>? existentMemeSubscription;

  final String id;

  CreateMemeBloc({
    final String? id,

    /// final String? selectedMemePath / ImagePicker  (main_bloc.dart   main_page.dart    create_meme_page.dart    create_meme_bloc.dart)
    final String? selectedMemePath,
  }) : this.id = id ?? Uuid().v4() {
    /// ImagePicker - memePathSubject.add(selectedMemePath);
    memePathSubject.add(selectedMemePath);
    _subscribeToNewMemTextOffset();
    _subscribeToExistentMeme();
  }

  void _subscribeToExistentMeme() {
    existentMemeSubscription =
        MemesRepository.getInstance().getMeme(this.id).asStream().listen(
      (meme) {
        if (meme == null) {
          return;
        }
        final memeTexts = meme.texts.map(
          (textWithPosition) {
            return MemeText(
                id: textWithPosition.id, text: textWithPosition.text);
          },
        ).toList();
        final memeTextOffset = meme.texts.map((textWithPosition) {
          return MemeTextOffset(
            id: textWithPosition.id,
            offset: Offset(
                textWithPosition.position.left, textWithPosition.position.top),
          );
        }).toList();
        memeTextSubject.add(memeTexts);
        memeTextOffsetsSubject.add(memeTextOffset);
        memePathSubject.add(meme.memePath);

        /// ImagePicker  memePathSubject.add(meme.memePath);
      },
      onError: (error, stackTrace) =>
          print('Error in existentMemeSubscription: $error, $stackTrace'),
    );
  }

  // late String id;
  // CreateMemeBloc({final String? id}) {
  //   this.id = id ?? Uuid().v4();
  //   _subscribeToNewMemTextOffset();
  // }

  void saveMeme() {
    final memeText = memeTextSubject.value;
    final memeTextOffsets = memeTextOffsetsSubject.value;

    final textsWithPositions = memeText.map((memeText) {
      final memeTextPosition =
          memeTextOffsets.firstWhereOrNull((memeTextOffset) {
        return memeTextOffset.id == memeText.id;
      });
      final position = Position(
          top: memeTextPosition?.offset.dy ?? 0,
          left: memeTextPosition?.offset.dx ?? 0);
      return TextWithPosition(
          id: memeText.id, text: memeText.text, position: position);
    }).toList();

    /// ImagePicker memePath: memePathSubject.value,
    saveMemeSubscription = SaveMemeInteractor.getInstance()
        .saveMeme(
          id: id,
          textWithPosition: textsWithPositions,
          imagePath: memePathSubject.value,
        )
        .asStream()
        .listen(
      (saved) {
        print('Meme saved: $saved');
      },
      onError: (error, stackTrace) =>
          print('Error in saveMemeSubscription: $error, $stackTrace'),
    );
  }

  // Future<bool> _saveMemeInternal(
  //   final List<TextWithPosition> textWithPosition,
  // ) async {
  //   final imagePath = memePathSubject.value;
  //   if (imagePath == null) {
  //     final meme = Meme(id: id, texts: textWithPosition);
  //     return MemesRepository.getInstance().addToMemes(meme);
  //   }
  //
  //   {
  //     final docsPath = await getApplicationDocumentsDirectory();
  //     final memePath =
  //         '${docsPath.absolute.path}${Platform.pathSeparator}memes';
  //     await Directory(memePath).create(recursive: true);
  //     final imageName = imagePath.split(Platform.pathSeparator).last;
  //     final newImageName = '$memePath${Platform.pathSeparator}$imageName';
  //     final tempFile = File(imagePath);
  //     await tempFile.copy(newImageName);
  //
  //     final meme = Meme(
  //       id: id,
  //       texts: textWithPosition,
  //       memePath: newImageName,
  //     );
  //     return MemesRepository.getInstance().addToMemes(meme);
  //   }
  // }

  void _subscribeToNewMemTextOffset() {
    newMemeTextOffsetSubscription = newMemeTextOffsetSubject
        .debounceTime(Duration(milliseconds: 300))
        .listen(
      (newMemeTextOffset) {
        if (newMemeTextOffset != null) {
          _changeMemeTextOffsetInternal(newMemeTextOffset);
        }
      },
      onError: (error, stackTrace) =>
          print('Error in newMemeTextOffsetSubscription: $error, $stackTrace'),
    );
  }

  void changeMemeTextOffset(final String id, final Offset offset) {
    newMemeTextOffsetSubject.add(MemeTextOffset(id: id, offset: offset));
  }

  void _changeMemeTextOffsetInternal(final MemeTextOffset newMemeTextOffset) {
    final copiedMemeTextOffset = [...memeTextOffsetsSubject.value];
    final currentMemeTextOffset = copiedMemeTextOffset.firstWhereOrNull(
        (memeTextOffset) => memeTextOffset.id == newMemeTextOffset.id);

    ///пытаемся найти текущее значение = берем memeTextOffsetsSubject -
    ///берем из него текущее значение value...
    // final newMemeTextOffset = MemeTextOffset(id: id, offset: offset);
    if (currentMemeTextOffset != null) {
      copiedMemeTextOffset.remove(currentMemeTextOffset);

      /// если не равен нулю то делаем remove object-найденый currentMemeTextOffset
    }
    copiedMemeTextOffset.add(newMemeTextOffset);

    /// и вставляем новое значение
    memeTextOffsetsSubject.add(copiedMemeTextOffset);
    // print('Got new offset: $newMemeTextOffset');
  }

  // void changeMemeTextOffset(final String id, final Offset offset) {
  //   final copiedMemeTextOffset = [...memeTextOffsetsSubject.value];
  //   final currentMemeTextOffset = copiedMemeTextOffset
  //       .firstWhereOrNull((memeTextOffset) => memeTextOffset.id == id);
  //
  //   ///пытаемся найти текущее значение = берем memeTextOffsetsSubject -
  //   ///берем из него текущее значение value...
  //   final newMemeTextOffset = MemeTextOffset(id: id, offset: offset);
  //   if (currentMemeTextOffset == null) {
  //     memeTextOffsetsSubject.add([
  //       ...copiedMemeTextOffset,
  //       newMemeTextOffset
  //
  //       /// если нет значения то добавляем текущее значение
  //     ]);
  //   } else {
  //     copiedMemeTextOffset.remove(currentMemeTextOffset);
  //     copiedMemeTextOffset.add(newMemeTextOffset);
  //         /// если не равен нулю то делаем remove object-найденый currentMemeTextOffset
  //     /// и вставляем новое значение
  //     memeTextOffsetsSubject.add(copiedMemeTextOffset);
  //
  //   }
  // }
  //
  // /// метод в котором передаем id  и offset-сдвиг - для выделенного текста

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

  /// ImagePicker - Stream<String?> observeMemePath() => memePathSubject.distinct();
  Stream<String?> observeMemePath() => memePathSubject.distinct();

  Stream<List<MemeText>> observeMemeText() => memeTextSubject
      .distinct((prev, next) => ListEquality().equals(prev, next));

  Stream<List<MemeTextWithOffset>> observeMemeTextWithOffsets() {
    return Rx.combineLatest2<List<MemeText>, List<MemeTextOffset>,
            List<MemeTextWithOffset>>(
        observeMemeText(), memeTextOffsetsSubject.distinct(),
        (memeTexts, memeTextOffsets) {
      return memeTexts.map((memeText) {
        final memeTextOffset = memeTextOffsets.firstWhereOrNull((element) {
          return element.id == memeText.id;
        });
        return MemeTextWithOffset(
          id: memeText.id,
          text: memeText.text,
          offset: memeTextOffset?.offset,
        );
      }).toList();
    }).distinct((prev, next) => ListEquality().equals(prev, next));
  }

  /// .distinct() оставляет только не повторяющиеся подряд значения
  /// ListEquality().equals(prev, next)) дает отличающиеся коллекции

  Stream<MemeText?> observeSelectedMemeText() =>
      selectedMemeTextSubject.distinct();

  /// ДЗ-6 возвращает лист с MemeTextWithSelection / название стрима observeMemeTextWithSelection()
  Stream<List<MemeTextWithSelection>> observeMemeTextWithSelection() {
    return Rx.combineLatest2<List<MemeText>, MemeText?,
            List<MemeTextWithSelection>>(
        observeMemeText(), observeSelectedMemeText(),
        (memeTexts, selectedMemeText) {
      ///   (a=memeTexts, b=selectedMemeText) {
      return memeTexts.map((memeText) {
        return MemeTextWithSelection(
            memeText: memeText, selected: memeText.id == selectedMemeText?.id);
      }).toList();
    });
  }

  /// список List<MemeText>, выделеный текст MemeText?, возвращаем MemeTextWithSelection
  void dispose() {
    memeTextSubject.close();
    selectedMemeTextSubject.close();
    memeTextOffsetsSubject.close();
    newMemeTextOffsetSubject.close();
    memePathSubject.close();

    newMemeTextOffsetSubscription?.cancel();
    saveMemeSubscription?.cancel();
    existentMemeSubscription?.cancel();
  }
}
