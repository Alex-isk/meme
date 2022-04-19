import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_bloc.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_selection.dart';
import 'package:memogenerator/presentation/main/main_bloc.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class CreateMemePage extends StatefulWidget {
  final String? id;

  ///
  final String? selectedMemePath;

  /// ImagePicker   (main_bloc.dart   main_page.dart    create_meme_page.dart    create_meme_bloc.dart)

  const CreateMemePage({Key? key, this.id, this.selectedMemePath})
      : super(key: key);

  ///

  @override
  _CreateMemePageState createState() => _CreateMemePageState();
}

class _CreateMemePageState extends State<CreateMemePage> {
  late CreateMemeBloc bloc;
  @override
  void initState() {
    super.initState();
    bloc = CreateMemeBloc(
      id: widget.id,
      selectedMemePath: widget.selectedMemePath,

      /// ImagePicker
    );
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
        resizeToAvoidBottomInset: false,

        /// при открытии клавиатуры не сдвигает экран
        appBar: AppBar(
          backgroundColor: AppColors.lemon,
          foregroundColor: AppColors.darkGrey,
          title: Text(
            'Создаём мем',
            style: GoogleFonts.seymourOne(),

            ///
          ),
          bottom: EditTextBar(),

          /// 1 нужен PreferredSizeWidget
          actions: [
            GestureDetector(
              onTap: () => bloc.saveMeme(),
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.save,
                    color: AppColors.darkGrey,
                  )),
            )
          ],
        ),
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: CreateMemePageContent(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class EditTextBar extends StatefulWidget implements PreferredSizeWidget {
  /// 2 поэтому нужно EditTextBar  преобразовать/наследуемся implements в PreferredSizeWidget абстракный класс
  /// 3 получаем его параметр - preferredSize
  const EditTextBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(68);

  @override
  State<EditTextBar> createState() => _EditTextBarState();
}

class _EditTextBarState extends State<EditTextBar> {
  final controller = TextEditingController();

  /// создаем контроллер
  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);

    /// 2C - прописываем блок
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: StreamBuilder<MemeText?>(

          /// 1С - вводимый текст - оборачиваем StreamBuilder<MemeText?>
          stream: bloc.observeSelectedMemeText(),

          /// слушаем блок
          builder: (context, snapshot) {
            final MemeText? selectedMemeText =
                snapshot.hasData ? snapshot.data : null;

            /// если в snapshot есть данные тогда возвращаем snapshot.data - в другом случае null
            if (selectedMemeText?.text != controller.text)

            /// если selectedMemeText не равен, то дабавляем - чтобы повторно не гонять по кругу
            {
              final newText = selectedMemeText?.text ?? '';

              /// каретка вконце слова при правке - переменную с условиями при каких...
              controller.text = selectedMemeText?.text ?? "";

              /// если selectedMemeText?.text = null то возврращаем  "" каретку
              controller.selection =
                  TextSelection.collapsed(offset: newText.length);

              /// каретка вконце слова при правке - если мы меняем текст в контроллере - каретка в конце
            }

            final haveSelected = selectedMemeText != null;
            return TextField(
              enabled: haveSelected,
              controller: controller,

              /// добавляем конроллер
              onChanged: (text) {
                if (haveSelected) {
                  ///если текст есть - то в соответствующем блоке меняем текст
                  bloc.changeMemeText(selectedMemeText!.id, text);
                }
              },
              onEditingComplete: () => bloc.deselectMemeText(),

              /// цвет курсора
              cursorColor: AppColors.fuchsia,

              /// обновляем соответствующий текcт - MemeText в нашем блоке
              decoration: InputDecoration(
                filled: true,

                /// фоновый текст hint
                hintText: haveSelected ? 'Ввести текст' : null,
                hintStyle: TextStyle(fontSize: 16, color: AppColors.darkGrey38),
                fillColor:
                    haveSelected ? AppColors.fuchsia16 : AppColors.darkGrey6,

                ///ДЗ-4-1 цвет подложки fillColor
                /// ДЗ-4-1
                disabledBorder: UnderlineInputBorder(
                  /// ДЗ-4-1 когда не выделен ни один текст
                  borderSide: BorderSide(color: AppColors.darkGrey38, width: 1),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.fuchsia38, width: 1),
                ),
                focusedBorder: UnderlineInputBorder(
                  /// фокус
                  borderSide: BorderSide(color: AppColors.fuchsia, width: 2),
                ),
              ),
            );
          }),
    );
  }

  /// 4. Оформить TextField
  ///     1. Сверстать состояние, когда не выделен ни один текст
  ///         1. Цвет заливки — Dark Grey 6%
  ///         2. Линия подчеркивания толщиной 1 логический пиксель цвета
  ///            Dark Grey 38%
  ///     2. В случае если текст еще не введен, но есть текущий выделенный текст:
  ///         1. Показывать "Ввести текст" в качестве хинта. В случае, если нет
  ///            текущего выделенного текста, то текст в хинте выводить не надо!
  ///         2. Этот текст должен иметь цвет Dark Grey 38% и размер 16
  ///     3. Сверстать состояние когда текст можно вводить, но фокуса в поле нет
  ///         1. Цвет заливки — Fuchsia 16%
  ///         2. Линия подчеркивания толщиной 1 логический пиксель цвета
  ///            Fuchsia 38%
  ///     4. Сверстать состояние с фокусом в виджете TextField
  ///         1. Цвет заливки — Fuchsia 16%
  ///         2. Линия подчеркивания толщиной 2 логических пикселя цвета Fuchsia
  ///         3. Курсор цвета Fuchsia

  @override
  void dispose() {
    controller.dispose;

    /// отписываемся от контроллера
    super.dispose();
  }
}

class CreateMemePageContent extends StatefulWidget {
  @override
  State<CreateMemePageContent> createState() => _CreateMemePageContentState();
}

class _CreateMemePageContentState extends State<CreateMemePageContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: MemeCanvasWidget(),
        ),
        Container(
          height: 1,
          width: double.infinity,
          color: AppColors.darkGrey,
        ),
        Expanded(
          flex: 1,
          child: BottomList(),
        ),
      ],
    );
  }
}

class BottomList extends StatelessWidget {
  const BottomList({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);

    return Container(
      color: AppColors.white,

      /// ДЗ-6
      child: StreamBuilder<List<MemeTextWithSelection>>(
        stream: bloc.observeMemeTextWithSelection(),
        initialData: const <MemeTextWithSelection>[],
        builder: (context, snapshot) {
          final items = snapshot.hasData
              ? snapshot.data!
              : const <MemeTextWithSelection>[];
          return ListView.separated(
            /// количество эллементов
            itemCount: items.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return const AddNewMemeTextButton();
              }
              final item = items[index - 1];
              return BottomMemeText(item: item);
            },

            separatorBuilder: (BuildContext context, int index) {
              /// Разделитель должен присутствовать только между элементами с
              ///            текстом. Таким образом его не должно быть между кнопкой с текстом
              ///            "ДОБАВИТЬ ТЕКСТ" и первым текстовым элементом
              if (index == 0) {
                return const SizedBox.shrink();

                ///  SizedBox.shrink с высотой 0 и шириной 0
              }
              return BottomSeparator();
            },
          );
        },
      ),
      // child: ListView.separated(
      //   itemCount: 1,
      //   separatorBuilder: (BuildContext context, int index) =>
      //       Container(height:1, color: AppColors.darkGrey, margin: EdgeInsets.only(left: 16),),
      //   itemBuilder: (BuildContext context, int index)
      //   {
      //     if (index == 0);
      //     {
      //       const AddNewMemeTextButton();
      //     }
      //
      //       return Container(
      //         // alignment: ,
      //           height: 48,
      //           padding: EdgeInsets.symmetric(horizontal: 16),
      //           child: Text(
      //               'text',textAlign: TextAlign.left, style: TextStyle(fontSize: 22))
      //       );
      //     }
      //
      // ),
    );
  }
}

class BottomSeparator extends StatelessWidget {
  const BottomSeparator({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 16),

      /// padding не подойдет тк уже исп выше
      height: 1,
      color: AppColors.darkGrey,
    );
  }
}

class BottomMemeText extends StatelessWidget {
  const BottomMemeText({
    Key? key,
    required this.item,
  }) : super(key: key);

  final MemeTextWithSelection item;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      color: item.selected ? AppColors.darkGrey16 : null,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      child: Text(
        item.memeText.text,
        style: TextStyle(color: AppColors.darkGrey, fontSize: 16),
      ),
    );
  }
}

/// 5. Добавление списка со всеми текстами внизу
///     1. В нижней части экрана, под кнопкой с текстом "Добавить текст"
///        добавить список со всеми текстами (MemeText), добавленными на экран
///     2. Добавлять элементы в тот же ListView, куда на занятии мы добавили
///        кнопку с текстом "Добавить текст"
///     3. Элемент в списке с текстом создать с помощью одного виджета Container
///         1. Указать корректные паддинги по 16 с боков
///         2. Высота виджет должна быть зафиксирована и равна 48
///         3. Текст должен быть отцентрирован по вертикали, но находится с
///            левой стороны
///         4. Стиль текста взять из макетов
///     4. Использовать специализированный конструктор у ListView, чтобы
///        добавить разделители между элементами
///         1. Разделитель должен присутствовать только между элементами с
///            текстом. Таким образом его не должно быть между кнопкой с текстом
///            "ДОБАВИТЬ ТЕКСТ" и первым текстовым элементом
///         2. Разделитель сверстать с помощью одного виджета Container
///         3. Слева должен быть отступ в 16
///         4. Высота разделителя равна 1
///         5. Цвет задника Dark Grey
class MemeCanvasWidget extends StatelessWidget {
  const MemeCanvasWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);

    /// 2В - прописываем блок - слушать ошибку

    return Container(
      color: AppColors.darkGrey38,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,

      /// 1. выравниваем
      child: AspectRatio(
        /// 2. соотношение ширины и высоты - например 16:9 -> 16/9 = 1.78
        aspectRatio: 1,

        ///3.    1 к 1 - это квадрат
        child: GestureDetector(
          onTap: () {
            bloc.deselectMemeText();
          },

          /// 2. Снятие выделения активного текста при нажатии вне текстовых блоков.
          ///     1. При нажатии на белый квадрат, вне областей с введенными текстами,
          ///        должно сбрасываться текущий выделенный текст.

          /// ДЗ-2 сбрасывать текст в TextField при нажатии на область белого квадрата - вне текста
          /// оборачиваем белый квадрат -контаинер GestureDetector с bloc.deselectMemeText()
          child: Stack(
            children: [
              /// ImagePicker - StreamBuilder ...
              StreamBuilder<String?>(
                  stream: bloc.observeMemePath(),
                  builder: (context, snapshot) {
                    final path = snapshot.hasData ? snapshot.data : null;
                    if (path == null) {
                      return Container(color: AppColors.white);
                    }
                    return Image.file(File(path));
                  }),
              StreamBuilder<List<MemeTextWithOffset>>(

                  /// 1В - оборачиваем Column() StreamBuilder
                  initialData: const <MemeTextWithOffset>[],

                  /// 4В пустой список
                  stream: bloc.observeMemeTextWithOffsets(),

                  /// 3В - вставляем прописанный блок
                  builder: (context, snapshot) {
                    final memeTextWithOffset = snapshot.hasData
                        ? snapshot.data!
                        : const <MemeTextWithOffset>[];

                    /// если в списке memeText есть данные - мы их получаем snapshot.hasData
                    /// иначе - если ничего нет - возвращаем пустой список <MemeText>[]
                    return LayoutBuilder(

                        ///

                        builder: (context, constraints) {
                      return Stack(
                        children: memeTextWithOffset.map((memeTextWithOffset) {
                          return DraggableMemeText(
                            memeTextWithOffset: memeTextWithOffset,
                            parentConstraints: constraints,
                          );
                        }).toList(),

                        /// 5В - memeText. мапим - превращаем из объекта memeText - объект виджет Техт
                        /// где в качестве текста memeText.text  и приводим к листу toList(),
                      );
                    });
                  }),
            ],
          ),
        ),
      ),
    );
  }
}

class DraggableMemeText extends StatefulWidget {
  final MemeTextWithOffset memeTextWithOffset;
  final BoxConstraints parentConstraints;

  /// ограничить рамки - чтобы текст не выходил - для LayoutBulder

  const DraggableMemeText({
    Key? key,
    required this.memeTextWithOffset,
    required this.parentConstraints,
  }) : super(key: key);

  @override
  State<DraggableMemeText> createState() => _DraggableMemeTextState();
}

class _DraggableMemeTextState extends State<DraggableMemeText> {
  late double top;
  late double left;
  // double top = 0;    убираем нуль
  // double left = 0;
  final double padding = 8;

  /// ДЗ-7
  @override
  void initState() {
    super.initState();
    top = widget.memeTextWithOffset.offset?.dy ??
        widget.parentConstraints.maxHeight / 2;
    left = widget.memeTextWithOffset.offset?.dx ??
        widget.parentConstraints.maxWidth / 3;
  }

  /// переменные для позиционирования
  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);

    return Positioned(
      /// передаем позицию виджета - необходимо перевести stless в stful !
      top: top,
      left: left,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        ///  с учетом паддингов можно перетаскивать слово, даже если нет цвета в контейнере
        onTap: () => bloc.selectMemeText(widget.memeTextWithOffset.id),
        onPanUpdate: (details) {
          /// местоположение текста
          /// ДЗ-1. Делать активным тот текст, который мы перетаскиваем по экрану
          ///     1. Выделять тот текст, который начали тащить (делать драг) по экрану
          bloc.selectMemeText(widget.memeTextWithOffset.id);

          /// ДЗ-1 выделение  и делать активным в textField текста при перетаскивании (драг)
          /// onPanUpdate: - отвечает за изменение местаположения текста + добавляем блок-выделеный текст с id
          // print('DRAG: ${details.globalPosition}');
          setState(() {
            /// ограничить размер контейнера <Size>
            left = calculateLeft(details);
            top = calculateTop(details);

            /// передвигать текст по экрану
            bloc.changeMemeTextOffset(
                widget.memeTextWithOffset.id, Offset(left, top));
          });
        },

        /// 3. Выделять текущий редактируемый виджет с текстом на фоне белого квадрата.
        ///     1. Выделять текущий выделенный текст в центральном виджете.
        ///         1. Цвет подложки Dark Grey 16%.
        ///         2. Граница вокруг с цветом Fuchsia и толщиной 1
        ///     2. Убрать выделение вокруг остальных текстов в центральном виджете.
        ///         1. Цвет подложки прозрачный
        ///         2. Границы вокруг быть не должно
        ///     3. Для задания нужного цвета и бордера используйте Container,
        ///        находящийся внутри DraggableMemeText

        /// ДЗ-3  выделять редактируемый текст - сделать серым16% на фоне белого квардрата

        child: StreamBuilder<MemeText?>(
          /// ДЗ-3-1  оборачиваем Container StreamBuilder
          stream: bloc.observeSelectedMemeText(),

          /// ДЗ-3-2 подписываемся на выделенный текст
          builder: (BuildContext context, AsyncSnapshot<MemeText?> snapshot) {
            final selectedItem = snapshot.hasData ? snapshot.data : null;
            final selected = widget.memeTextWithOffset.id == selectedItem?.id;
            // if (snapshot.hasData) {
            // //  if (snapshot.hasData ? snapshot.data : null) {
            /// ДЗ-3-3 если есть данные, то возвращаем  Container с цветом16% + граница fuchsia
            return MemeTextOnCanvas(
              padding: padding,
              selected: selected,
              parentConstraints: widget.parentConstraints,
              text: widget.memeTextWithOffset.text,
            );
          },
        ),

        // child: StreamBuilder<MemeText?>(
        //   /// ДЗ-3-1  оборачиваем Container StreamBuilder
        //   stream: bloc.observeSelectedMemeText(),
        //
        //   /// ДЗ-3-2 подписываемся на выделенный текст
        //   builder: (BuildContext context, AsyncSnapshot<MemeText?> snapshot) {
        //     final selectedItem = snapshot.hasData ? snapshot.data : null;
        //     final selected = widget.memeTextWithOffset.id == selectedItem?.id;
        //     // if (snapshot.hasData) {
        //     // //  if (snapshot.hasData ? snapshot.data : null) {
        //     /// ДЗ-3-3 если есть данные, то возвращаем  Container с цветом16% + граница fuchsia
        //     return Container(
        //       constraints: BoxConstraints(
        //         maxWidth: widget.parentConstraints.maxWidth,
        //
        //         ///ограничить размер вводимого текста + ограничить размер контейнера см выше <Size>
        //         maxHeight: widget.parentConstraints.maxHeight,
        //       ),
        //       padding: EdgeInsets.all(padding),
        //       decoration: BoxDecoration(
        //         color: selected ? AppColors.darkGrey16 : null,
        //         border: Border.all(
        //             color: selected ? AppColors.fuchsia : Colors.transparent,
        //             width: 1),
        //       ),
        //
        //       /// alt+cmdV -  вынос параметров
        //       child: Text(
        //         widget.memeTextWithOffset.text,
        //         textAlign: TextAlign.center,
        //         style: TextStyle(
        //           color: AppColors.black,
        //           fontSize: 24,
        //         ),
        //       ),
        //     );
        //   },
        // ),
      ),
    );
  }

  /// ДЗ-3-4 Иначе возвращаем Container прозрачной подложкой и без границы
  // } else {
  //   return Container(
  //     constraints: BoxConstraints(
  //       maxWidth: widget.parentConstraints.maxWidth,
  //       maxHeight: widget.parentConstraints.maxHeight,
  //     ),
  //     padding: EdgeInsets.all(padding),
  //     decoration: BoxDecoration(
  //       color: AppColors.transparent,
  //     ),
  //     child: Text(
  //       widget.memeText.text,
  //       textAlign: TextAlign.center,
  //       style: TextStyle(
  //         color: AppColors.black,
  //         fontSize: 24,
  //       ),
  //     ),
  //   );

  double calculateTop(DragUpdateDetails details) {
    final rawTop = top + details.delta.dy;
    if (rawTop < 0) {
      return 0;
    }
    if (rawTop > widget.parentConstraints.maxHeight - padding * 2 - 24) {
      /// если превышение паддингов - возврат к мин параметрам
      return widget.parentConstraints.maxHeight - padding * 2 - 24;
    }
    return rawTop;
  }

  double calculateLeft(DragUpdateDetails details) {
    /// текст не может выходить за левую границу экрана
    final rawLeft = left + details.delta.dx;
    if (rawLeft < 0) {
      return 0;
    }
    if (rawLeft > widget.parentConstraints.maxWidth - padding * 2 - 10) {
      return widget.parentConstraints.maxWidth - padding * 2 - 10;
    }
    return rawLeft;
  }
}

class MemeTextOnCanvas extends StatelessWidget {
  final double padding;
  final bool selected;
  final BoxConstraints parentConstraints;
  final String text;

  const MemeTextOnCanvas({
    Key? key,
    required this.padding,
    required this.selected,
    required this.parentConstraints,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: parentConstraints.maxWidth,
        maxHeight: parentConstraints.maxHeight,
      ),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: selected ? AppColors.darkGrey16 : null,
        border: Border.all(
            color: selected ? AppColors.fuchsia : Colors.transparent, width: 1),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.black,
          fontSize: 24,
        ),
      ),
    );
  }
}

class AddNewMemeTextButton extends StatelessWidget {
  const AddNewMemeTextButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);

    /// получаем блок
    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      ///
      onTap: () => bloc.addNewText(),

      /// вызаваем блок - новый вводимый текст
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                color: AppColors.fuchsia,
              ),
              const SizedBox(width: 8),
              Text(
                'Добавить текст'.toUpperCase(),
                style: TextStyle(
                  color: AppColors.fuchsia,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
