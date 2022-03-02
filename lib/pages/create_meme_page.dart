import 'package:flutter/material.dart';
import 'package:memogenerator/blocs/create_meme_bloc.dart';
import 'package:memogenerator/blocs/main_bloc.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class CreateMemePage extends StatefulWidget {
  @override
  _CreateMemePageState createState() => _CreateMemePageState();
}

class _CreateMemePageState extends State<CreateMemePage> {
  late CreateMemeBloc bloc;
  @override
  void initState() {
    super.initState();
    bloc = CreateMemeBloc();
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

            /// если selectedMemeText не равен, то дабавляем - чтобы посторно не гонять по кругу
            {
              final newText = selectedMemeText?.text ?? '';

              /// каретка вконце слова при правке - переменную с условиями при каких...
              controller.text = selectedMemeText?.text ?? "";

              /// еслли selectedMemeText?.text = null то возврращаем  ""
              controller.selection =
                  TextSelection.collapsed(offset: newText.length);

              /// каретка вконце слова при правке - если мы меняем текст в контроллере - каретка вконце
            }
            return TextField(
              enabled: selectedMemeText != null,
              controller: controller,

              /// добавляем конроллер
              onChanged: (text) {
                if (selectedMemeText != null) {
                  ///если текст есть - то в соответствующем блоке меняем текст

                  bloc.changeMemeText(selectedMemeText.id, text);
                }
              },
              onEditingComplete: () => bloc.deselectMemeText(),

              /// обновляем соответствующий текcт - MemeText в нашем блоке
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.darkGrey6,
              ),
            );
          }),
    );
  }

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
    return Center(
      child: Column(
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
            child: Container(
              color: AppColors.white,
              child: ListView(
                children: [
                  const SizedBox(height: 12),
                  const AddNewMemeTextButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
        child: Container(
          color: AppColors.white,
          child: StreamBuilder<List<MemeText>>(

              /// 1В - оборачиваем Column() StreamBuilder
              initialData: const <MemeText>[],

              /// 4В пустой список
              stream: bloc.observeMemeText(),

              /// 3В - вставляем прописанный блок
              builder: (context, snapshot) {
                final memeText =
                    snapshot.hasData ? snapshot.data! : const <MemeText>[];

                /// если в списке memeText есть данные - мы их получаем snapshot.hasData
                /// иначе - если ничего нет - возвращаем пустой список <MemeText>[]
                return LayoutBuilder(

                    ///

                    builder: (context, constraints) {
                  return Stack(
                    children: memeText.map((memeText) {
                      return DraggableMemeText(
                        memeText: memeText,
                        parentConstraints: constraints,
                      );
                    }).toList(),

                    /// 5В - memeText. мапим - превращаем из объекта memeText - объект виджет Техт
                    /// где в качестве текста memeText.text  и приводим к листу toList(),
                  );
                });
              }),
        ),
      ),
    );
  }
}

class DraggableMemeText extends StatefulWidget {
  final MemeText memeText;
  final BoxConstraints parentConstraints;

  /// ограничить рамки - чтобы текст не выходил - для LayoutBulder

  const DraggableMemeText({
    Key? key,
    required this.memeText,
    required this.parentConstraints,
  }) : super(key: key);

  @override
  State<DraggableMemeText> createState() => _DraggableMemeTextState();
}

class _DraggableMemeTextState extends State<DraggableMemeText> {
  double top = 0;
  double left = 0;
  final double padding = 8;

  /// переменные для позиционирования
  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);

    return Positioned(
      /// передаем позицию виджета - необходимо перевести stless в stful
      top: top,
      left: left,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        ///  с учетом падингов можно перетаскивать слово, даже если нет цвета в контейнере
        onTap: () => bloc.selectMemeText(widget.memeText.id),
        onPanUpdate: (details) {
          // print('DRAG: ${details.globalPosition}');
          setState(() {
            /// ограничить размер контейнера
            left = calculateLeft(details);
            top = calculateTop(details);
          });
        },

        /// передвигать текст по экрану
        child: Container(
          constraints: BoxConstraints(
            maxWidth: widget.parentConstraints.maxWidth,
            maxHeight: widget.parentConstraints.maxHeight,
          ),

          ///ограничить размер вводимого текста -и  ограничить размер контейнера см выше
          padding: EdgeInsets.all(padding),

          /// alt+cmd+V -  вынос параметров
          color: AppColors.darkGrey6,

          ///
          child: Text(
            widget.memeText.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 24,
            ),
          ),
        ),
      ),
    );
  }

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
