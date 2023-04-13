package;

import Controls.Control;
import flixel.math.FlxMath;
import Song.SwagSong;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.addons.display.FlxBackdrop;
import openfl.filters.ShaderFilter;
import flixel.util.FlxTimer;
import android.FlxVirtualPad;

//stolen from sonic exe lol
class PauseSubState extends MusicBeatSubstate
{
        var virtualPad:FlxVirtualPad;

	var grpMenuShit:FlxTypedGroup<FlxSprite>;

	var grpMenuShit2:FlxTypedGroup<FlxSprite>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Exit to menu'];
	var difficultyChoices = [];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;

	var camThing:FlxCamera;

	var colorSwap:ColorSwap;

	var grayButton:FlxSprite;

	var bottomPause:FlxSprite;
	var topPause:FlxSprite;

        public static var songName:String = '';
        var charSpr:FlxSprite;

	var coolDown:Bool = true;
	public var boyfriend:Boyfriend;
	var songPercent:Float = 0;

	public static var transCamera:FlxCamera;

	var creditsText:FlxTypedGroup<FlxText>;
	var creditoText:FlxText;

	private var curSong:String = "";

	public function new(x:Float, y:Float)
	{



		camThing = new FlxCamera();
		camThing.bgColor.alpha = 0;
		FlxG.cameras.add(camThing);

		super();
		menuItems = menuItemsOG;

		FlxG.sound.play(Paths.sound("pause"));

		for (i in 0...CoolUtil.difficulties.length) {
			var diff:String = '' + CoolUtil.difficulties[i];
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');

		pauseMusic = new FlxSound();
		if(songName != null) {
			pauseMusic.loadEmbedded(Paths.music(songName), true, true);
		} else if (songName != 'None') {
			pauseMusic.loadEmbedded(Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic)), true, true);
		}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		boyfriend = new Boyfriend(0, 0, PlayState.SONG.player1);

		bottomPause = new FlxSprite(1280, 33).loadGraphic(Paths.image('pauseStuff/bottomPanel'));
		FlxTween.tween(bottomPause, {x: 589}, 0.2, {ease: FlxEase.quadOut});
		add(bottomPause);


		topPause = new FlxSprite(-1000, 0).loadGraphic(Paths.image("pauseStuff/pauseTop"));
		add(topPause);
		FlxTween.tween(topPause, {x: 0}, 0.2, {ease: FlxEase.quadOut});

                charSpr = new FlxSprite(-1000, 0).loadGraphic(Paths.image("pauseStuff/" + PlayState.SONG.player2));
                add(charSpr);
                FlxTween.tween(charSpr, {x: 0}, 0.5, {ease: FlxEase.quadOut});

		var levelInfo:FlxText = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += PlayState.SONG.song;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += CoolUtil.difficultyString();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		var blueballedTxt:FlxText = new FlxText(20, 15 + 64, 0, "", 32);
		blueballedTxt.text = "Blueballed: " + PlayState.deathCounter;
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.font('vcr.ttf'), 32);
		blueballedTxt.updateHitbox();
		add(blueballedTxt);

		blueballedTxt.alpha = 0;
		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);

		/*
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});
		*/
		grayButton = new FlxSprite().loadGraphic(Paths.image('pauseStuff/graybut'));
		grayButton.x = FlxG.width - 400 + 480;
		grayButton.y = FlxG.height / 2 + 70;
		FlxTween.tween(grayButton, {x: grayButton.x - 480}, 0.2, {ease: FlxEase.quadOut});
		add(grayButton);

		grpMenuShit = new FlxTypedGroup<FlxSprite>();
		add(grpMenuShit);

		grpMenuShit2 = new FlxTypedGroup<FlxSprite>();
		add(grpMenuShit2);

		for (i in 0...menuItems.length)
		{
			var songText:FlxSprite = new FlxSprite(FlxG.width + 400 + 80 * i, FlxG.height / 2 + 70 + 100 * i);
			songText.loadGraphic(Paths.image("pauseStuff/blackbut"));
			songText.x += (i + 1) * 480;
			songText.ID = i;
			FlxTween.tween(songText, {x: songText.x - 480 * (i + 1)}, 0.2, {ease: FlxEase.quadOut});
			grpMenuShit.add(songText);
			var actualText:FlxSprite = new FlxSprite(songText.x + 25, songText.y + 25).loadGraphic(Paths.image(StringTools.replace("pauseStuff/" + menuItems[i], " ", "")));
			actualText.ID = i;
			actualText.x += (i + 1) * 480;
			actualText.y = FlxG.height / 2 + 70 + 100 * i + 5;

			FlxTween.tween(actualText, {x: FlxG.width - 400 - 80 * i + 25}, 0.2, {ease: FlxEase.quadOut});
			grpMenuShit2.add(actualText);
		}

		coolDown = false;
		new FlxTimer().start(0.2, function(lol:FlxTimer)
		{
			coolDown = true;
			changeSelection();
		});
		cameras = [camThing];
                #if mobile addVirtualPad(UP_DOWN, A); addPadCamera(); #end
	}

	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		//super.update(elapsed);

		var upP = controls.UI_UP_P #if mobile || virtualPad.buttonUp.justPressed #end;
		var downP = controls.UI_DOWN_P #if mobile || virtualPad.buttonDown.justPressed #end;
		var accepted = controls.ACCEPT;

		if (coolDown)
		{
			if (upP)
			{
				changeSelection(-1);
			}
			if (downP)
			{
				changeSelection(1);
			}

			if (accepted)
			{
				var daSelected:String = menuItems[curSelected];
				for (i in 0...difficultyChoices.length-1) {
					if(difficultyChoices[i] == daSelected) {
						var name:String = PlayState.SONG.song.toLowerCase();
						var poop = Highscore.formatSong(name, curSelected);
						PlayState.SONG = Song.loadFromJson(poop, name);
						PlayState.storyDifficulty = curSelected;
						MusicBeatState.resetState();
						FlxG.sound.music.volume = 0;
						PlayState.changedDifficulty = true;
						return;
					}
				}
				switch (daSelected)
				{

					case "Resume":

						coolDown = false;
						FlxG.sound.play(Paths.sound("unpause"));
						grpMenuShit.forEach(function(item:FlxSprite)
						{
							FlxTween.tween(item, {x: item.x + 480 * (item.ID + 1)}, 0.2, {ease: FlxEase.quadOut});
						});
						grpMenuShit2.forEach(function(item2:FlxSprite)
						{
							FlxTween.tween(item2, {x: item2.x + 480 * (item2.ID + 1)}, 0.2, {ease: FlxEase.quadOut});
						});
						FlxTween.tween(grayButton, {x: grayButton.x + 480 * (curSelected + 1)}, 0.2, {ease: FlxEase.quadOut});

						FlxTween.tween(topPause, {x: -1000}, 0.2, {ease: FlxEase.quadOut});
						FlxTween.tween(bottomPause, {x: 1280}, 0.2, {ease: FlxEase.quadOut, onComplete: function(ok:FlxTween)
						{
							close();
						}});
					case "Restart Song":
						restartSong();
						MusicBeatState.resetState();
						FlxG.sound.music.volume = 0;
					case "Exit to menu":
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;

					WeekData.loadTheFirstEnabledMod();
					if(PlayState.isStoryMode) {
						MusicBeatState.switchState(new StoryMenuState());
					} else {
						MusicBeatState.switchState(new FreeplayState());
					}
					PlayState.cancelMusicFadeTween();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;
				}
			}
		}
		super.update(elapsed);
	}
	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.instance.paused = true; // For lua
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		}
		else
		{
			MusicBeatState.resetState();
		}
	}

	override function destroy()
	{
		camThing.destroy();
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (change == 1 || change == -1) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;



		for (item in grpMenuShit.members)
		{
			FlxTween.cancelTweensOf(item);

			item.x = FlxG.width - 400 - 80 * item.ID;
			item.y = FlxG.height / 2 + 70 + 100 * item.ID;


			if (item.ID == curSelected)
			{
				FlxTween.cancelTweensOf(grayButton);
				grayButton.x = FlxG.width - 400 - 80 * item.ID;
				grayButton.y = FlxG.height / 2 + 70 + 100 * item.ID;
				FlxTween.tween(item, {y: FlxG.height / 2 + 70 + 100 * item.ID - 20}, 0.2, {ease: FlxEase.quadOut, onComplete: function(lol:FlxTween)
				{
					FlxTween.tween(item, {y: item.y + 5}, 1, {ease: FlxEase.quadOut, type: FlxTween.PINGPONG});
					FlxTween.tween(grayButton, {y: grayButton.y - 5}, 1, {ease: FlxEase.quadInOut, type: FlxTween.PINGPONG});
				}});

			}
			else
			{
				FlxTween.tween(item, {y: FlxG.height / 2 + 70 + 100 * item.ID}, 0.2, {ease: FlxEase.quadOut});
			}
			// item.setGraphicSize(Std.int(item.width * 0.8));
		}
		for (item in grpMenuShit2.members)
		{
			FlxTween.cancelTweensOf(item);
			item.x = grpMenuShit.members[item.ID].x + 25;
			item.y = FlxG.height / 2 + 70 + 100 * item.ID + 5;

			if (item.ID == curSelected) FlxTween.tween(item, {y: FlxG.height / 2 + 70 + 100 * item.ID - 20 + 5}, 0.2, {ease: FlxEase.quadOut, onComplete: function(lol:FlxTween)
			{
				FlxTween.tween(item, {y: item.y + 5}, 1, {ease: FlxEase.quadInOut, type: FlxTween.PINGPONG});
			}});
			else FlxTween.tween(item, {y: FlxG.height / 2 + 70 + 100 * item.ID + 5}, 0.2, {ease: FlxEase.quadOut});
		}
	}


	/*
	function regenMenu():Void {
		for (i in 0...grpMenuShit.members.length) {
			this.grpMenuShit.remove(this.grpMenuShit.members[0], true);
		}
		for (i in 0...menuItems.length) {
			var item = new Alphabet(0, 70 * i + 30, menuItems[i], true, false);
			item.isMenuItem = true;
			item.targetY = i;
			grpMenuShit.add(item);
		}
		curSelected = 0;
		changeSelection();
	}
	*/
}
