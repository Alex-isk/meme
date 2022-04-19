import 'package:flutter/material.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/presentation/main/main_bloc.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_page.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  // State<MainPage> createState() => _MainPageState();
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late MainBloc bloc;
  @override
  void initState() {
    super.initState();
    bloc = MainBloc();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.lemon,
          foregroundColor: AppColors.darkGrey,
          centerTitle: true,

          /// название по центру по умолчанию
          title: Text(
            'Мемогенератор',
            style: GoogleFonts.seymourOne(fontSize: 24),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {     /// async   / ImagePicker /  (main_bloc.dart   main_page.dart    create_meme_page.dart    create_meme_bloc.dart)
            final selectedMemePath = await bloc.selectMeme();  /// ImagePicker
            if (selectedMemePath == null) { /// ImagePicker / если не выбрали мем
              return;         /// ImagePicker
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateMemePage(
                 selectedMemePath: selectedMemePath, /// ImagePicker
                ),

                ///  builder: (_) подчеркивание в скобочках показывает,
                ///  что мы ингнорируем этот параметр, можем не указывать ни имя ни тип
              ),
            );
          },
          icon: Icon(
            Icons.add,
            color: AppColors.white,
          ),
          label: Text('Создать'),
          backgroundColor: AppColors.fuchsia,
        ),
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: MainPageContent(),
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

class MainPageContent extends StatefulWidget {
  @override
  State<MainPageContent> createState() => _MainPageContentState();
}

class _MainPageContentState extends State<MainPageContent> {
  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return StreamBuilder<List<Meme>>(
        stream: bloc.observeMemes(),
        initialData: const <Meme>[],
        builder: (context, snapshot) {
          final items = snapshot.hasData ? snapshot.data! : const <Meme>[];
          return ListView(
            children: items.map((item) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {
                      return CreateMemePage(id: item.id);
                    },
                    ),
                  );
                },
                child: Container(
                  height: 48,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Text(item.id),
                ),
              );
            }).toList(),
          );
        });
  }
}
