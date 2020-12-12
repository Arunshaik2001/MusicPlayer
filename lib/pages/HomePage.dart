import 'package:alan_voice/alan_voice.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_player/model/Radio.dart';
import 'package:music_player/utils/AiUtil.dart';
import 'package:velocity_x/velocity_x.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MyRadio> radio;
  MyRadio selectedRadio;
  Color selectedColor;
  bool isPlaying = false;
  final _audioPlayer = AudioPlayer();
  playAudio(MyRadio rad) {
    _audioPlayer.play(rad.url);
    selectedRadio = rad;
    setState(() {});
  }

  fetchRadios() async {
    final radioJson = await rootBundle.loadString("assets/radio.json");
    radio = MyRadioList
        .fromJson(radioJson)
        .radios;
    selectedRadio=radio[0];
    selectedColor=Color(int.tryParse(selectedRadio.color));
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setupAlan();
    fetchRadios();


    _audioPlayer.onPlayerStateChanged.listen((event) {
      if (event == AudioPlayerState.PLAYING)
        isPlaying = true;
      else
        isPlaying = false;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: selectedColor ?? AiColor.primaryColour2,
          child: radio != null
              ? [
            100.heightBox,
            "All Channels".text.xl.white.semiBold.make().px16(),
            20.heightBox,
            ListView(
              padding: Vx.m0,
              shrinkWrap: false,
              children: radio
                  .map((e) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(e.icon),
                ),
                title: "${e.name} FM".text.white.make(),
                subtitle: e.tagline.text.white.make(),
              ))
                  .toList(),
            ).expand()
          ].vStack(crossAlignment: CrossAxisAlignment.start)
              : const Offstage(),
        ),
      ),
      body: Stack(
        children: [
          VxAnimatedBox()
              .size(context.screenWidth, context.screenHeight)
              .withGradient(
            LinearGradient(
              colors: [
                AiColor.primaryColour2,
                selectedColor??AiColor.primaryColour1,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          )
              .make(),
          AppBar(
            backgroundColor: Colors.transparent,
            title: "MusicPlayer".text.bold.xl4.white.make().shimmer(
              primaryColor: Vx.purple300,
              secondaryColor: Colors.white,
            ),
            elevation: 0.0,
            centerTitle: true,
          ).h(100.0).p16(),
          radio!=null?VxSwiper.builder(
              onPageChanged: (index){
                if(!isPlaying)selectedRadio=radio[index];
                selectedColor=Color(int.tryParse(radio[index].color));
                if(!isPlaying)selectedRadio=radio[index];
                setState(() {});
              },
              height: 370.0,
              enlargeCenterPage: true,
              itemCount: radio.length,
              itemBuilder: (_, index) {
                var rad = radio[index];
                return VxBox(
                    child: ZStack([
                      Positioned(
                        top: 0.0,
                        right: 0.0,
                        child: VxBox(
                          child: rad.category.text.uppercase.white.make()
                              .px16(),
                        )
                            .height(40)
                            .black

                            .alignCenter
                            .withRounded(value: 10.0)
                            .make(),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: VStack(
                          [
                            rad.name.text.white.bold.xl3.make(),
                            5.heightBox,
                            rad.tagline.text.sm.white.semiBold.make(),
                          ],
                          crossAlignment: CrossAxisAlignment.center,
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: [
                          Icon(!isPlaying?CupertinoIcons.play_circle:CupertinoIcons.stop_circle).iconColor(Colors.white).iconSize(30.0),
                          10.heightBox,
                          "Tap Tap....".text.gray100.make(),
                        ].vStack(),
                      )
                    ]))
                    .clip(Clip.antiAlias)
                    .bgImage(
                  DecorationImage(
                    image: NetworkImage(rad.image),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.3), BlendMode.darken),
                  ),
                )
                    .border(color: Colors.black, width: 5.0)
                    .withRounded(value: 60.0)
                    .make()
                    .onInkTap(() {
                      if(!isPlaying)
                        playAudio(rad);
                      else _audioPlayer.stop();
                    })
                    .p16();
              }).centered():Center(
            child: CircularProgressIndicator(backgroundColor: Colors.white,),
          ),
          Align(
              alignment: Alignment.bottomCenter,
              child: [
                if(isPlaying)"Playing Now ${selectedRadio.name}".text.white.bold
                    .makeCentered(),
                Icon(!isPlaying
                    ? CupertinoIcons.play_circle
                    : CupertinoIcons.stop_circle).iconColor(Colors.white).iconSize(40.0).onInkTap(() {
                      if(isPlaying)_audioPlayer.stop();
                      else playAudio(selectedRadio);
                }),
              ].vStack()
          ).pOnly(bottom: context.percentHeight * 12)
        ]
        ,
        fit: StackFit.expand,
        clipBehavior: Clip.antiAlias,
      ),
    );
  }

  void setupAlan() {
    AlanVoice.addButton(
        "4e7ddada78e59d92add7bfd140fc81a52e956eca572e1d8b807a3e2338fdd0dc/stage",
        buttonAlign: AlanVoice.BUTTON_ALIGN_RIGHT);
    AlanVoice.callbacks.add((command) => _handleCommand(command.data));
  }

  _handleCommand(Map<String, dynamic> data) {
    switch(data["command"]){
      case "play":
        playAudio(selectedRadio);
        break;

      case "stop":
        _audioPlayer.stop();
        break;

      case "next":
        int currentId=selectedRadio.id;
        int nextRadioId=(currentId+1)%radio.length;
        MyRadio newRadio=radio.firstWhere((element) => element.id==nextRadioId);
        radio.remove(newRadio);
        radio.insert(0, newRadio);
        playAudio(newRadio);
        break;

      case "prev":
        int currentId=selectedRadio.id;
        int nextRadioId=currentId-1<0?radio.length-1:currentId-1;
        MyRadio newRadio=radio.firstWhere((element) => element.id==nextRadioId);
        radio.remove(newRadio);
        radio.insert(0, newRadio);
        playAudio(newRadio);
        break;

      case "play_channel":
        int fetchedChannelId=data["id"];
        _audioPlayer.pause();
        MyRadio newRadio=radio.firstWhere((element) => element.id == fetchedChannelId);
        radio.remove(newRadio);
        radio.insert(0, newRadio);
        playAudio(newRadio);
        break;
      case "play_channel":
        int fetchedChannelId=data["id"];
        _audioPlayer.pause();
        MyRadio newRadio=radio.firstWhere((element) => element.id == fetchedChannelId);
        radio.remove(newRadio);
        radio.insert(0, newRadio);
        playAudio(newRadio);
        break;



      default:
        print("command was ${data["command"]}");
    }
  }


}
