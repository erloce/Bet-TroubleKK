package;

#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import lime.utils.Assets;
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import flixel.addons.display.FlxBackdrop;
import flixel.tweens.FlxEase;
import WeekData;
#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

//Sonic exe lol
class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	private static var curSelected:Int = 0;
	var curSong:Int = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = '';

	var songText:FlxText;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	var bg:FlxSprite;
	var backdropline:FlxBackdrop;
	var backdropline2:FlxBackdrop;
	var grupo:FlxTypedGroup<FlxSprite>;
	var grupoImagen:FlxTypedGroup<FlxSprite>;
	var grupoTexto:FlxTypedGroup<FlxText>;

	override function create()
	{
		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();

		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		
		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;
			
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];
			
			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			addSong(leSongs, i);
		}
		WeekData.loadTheFirstEnabledMod();

		bg = new FlxSprite().loadGraphic(Paths.image('freeplay/backgroundlool'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.screenCenter();
		bg.setGraphicSize(1280, 720);
		add(bg);

		var line:FlxSprite = new FlxSprite(FlxG.width/4-5).makeGraphic(10, 720, FlxColor.BLACK);
		add(line);

		backdropline = new FlxBackdrop(Paths.image('freeplay/sidebar'), 1, 1, false, true, 0, 0);
		backdropline.velocity.set(0,50);
		backdropline.antialiasing = ClientPrefs.globalAntialiasing;
		add(backdropline);

		backdropline2 = new FlxBackdrop(Paths.image('freeplay/sidebar2'), 1, 1, false, true, 0, 0);
		backdropline2.velocity.set(0,-50);
		backdropline2.antialiasing = ClientPrefs.globalAntialiasing;
		add(backdropline2);

		grupoImagen = new FlxTypedGroup<FlxSprite>();
		add(grupoImagen);

		grupo = new FlxTypedGroup<FlxSprite>();
		add(grupo);

		grupoTexto = new FlxTypedGroup<FlxText>();
		add(grupoTexto);

		for (i in 0...songs.length)
		{
			var box:FlxSprite = new FlxSprite();
			box.loadGraphic(Paths.image('freeplay/FreeBox'));
			box.x=FlxG.width / 2 -(box.width/2);
			box.y= FlxG.height / 2 -(box.height/2) + (i * 415);
			box.antialiasing = ClientPrefs.globalAntialiasing;
			box.ID = i;
			grupo.add(box);


			var imagen:FlxSprite = new FlxSprite();
			imagen.loadGraphic(Paths.image('freeplay/weeks/'+ WeekData.weeksList[i]));
			imagen.x=FlxG.width / 2 -(imagen.width/2);
			imagen.y= FlxG.height / 2 -(imagen.height/2) + (i * 415);
			imagen.antialiasing = ClientPrefs.globalAntialiasing;
			imagen.ID = i;
			grupoImagen.add(imagen);

		}
		WeekData.setDirectoryFromWeek();

		songText = new FlxText(0,5,0, "");
		songText.setFormat(Paths.font("PhantomMuff.ttf"),60, FlxColor.WHITE, CENTER);
		add(songText);

		diffText = new FlxText(0,songText.y + 86,0, "",18);
		diffText.font = songText.font;
		add(diffText);

		scoreText = new FlxText(0,diffText.y+ 50, 0, "",18);
		scoreText.font = diffText.font;

		add(scoreText);

		if(lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		
		changeSelection();
		changeSong();
		changeDiff();
		super.create();

                #if android
                addVirtualPad(FULL, A_B_C_X_Y_Z);
                #end
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:Array<String>, weekNum:Int)
	{
		songs.push(new SongMetadata(songName, weekNum));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}


	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;

	var weekOn:Bool;

	override function update(elapsed:Float)
	{

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		songText.text = WeekData.weeksList[curSelected];

		scoreText.text = 'Score  ' + lerpScore;
		positionHighscore();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var space = FlxG.keys.justPressed.SPACE #if android || _virtualpad.buttonX.justPressed #end;
		var ctrl = FlxG.keys.justPressed.CONTROL #if android || _virtualpad.buttonC.justPressed #end;

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT #if android || _virtualpad.buttonZ.pressed #end) shiftMult = 3;

		if(weekOn){
			diffText.visible = true;
			scoreText.visible = true;

			if (upP)
			{
				changeSong(-shiftMult);
				
			}

			if (downP)
			{
				changeSong(shiftMult);
				holdTime = 0;
			}

			if (controls.UI_LEFT_P)
				changeDiff(-1);
			else if (controls.UI_RIGHT_P)
				changeDiff(1);
			else if (upP||downP) 
				changeDiff();

		}
		else
		{
			scoreText.visible = false;
			diffText.visible = false;

			if(songs.length > 1)
			{
				if (upP)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}

				if (downP)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}
		
				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
		
					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
		
				if(FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
			}
		}

		if (controls.BACK)
		{
			if(weekOn){
				weekOn = false;
				instPlaying = -1;
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			else{
				persistentUpdate = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
		
		}

		if(ctrl)
		{
			#if android
			removeVirtualPad();
			#end

			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(space && weekOn)
		{
			if(instPlaying != curSong)
			{
				#if PRELOAD_ALL
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				Paths.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName[curSong].toLowerCase(), curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName[curSong].toLowerCase());
				if (PlayState.SONG.needsVoices)
					vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
				else
					vocals = new FlxSound();

				FlxG.sound.list.add(vocals);
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
				vocals.play();
				vocals.persist = true;
				vocals.looped = true;
				vocals.volume = 0.7;
				instPlaying = curSong;
				#end
			}
		}

		else if (accepted){

			if(!weekOn){
				weekOn = true;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				changeDiff();
				changeSong();
			}
			else
			{
				persistentUpdate = false;
				var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName[curSong]);
				var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
		
				trace(poop);

				PlayState.SONG = Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;

				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			
				if (FlxG.keys.pressed.SHIFT #if android || _virtualpad.buttonZ.pressed #end){
					LoadingState.loadAndSwitchState(new ChartingState());
				}else{
				LoadingState.loadAndSwitchState(new PlayState());
				}

				FlxG.sound.music.volume = 0;
					
				destroyFreeplayVocals();
			}
		}
		
		else if(controls.RESET #if android || _virtualpad.buttonY.justPressed #end && weekOn)
		{
			#if android
			removeVirtualPad();
			#end

			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName[curSong], curDifficulty, 'bf'));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		super.update(elapsed);
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function songList(actualizar:Bool) {
		if(actualizar){
			for (i in 0...songs[curSelected].songName.length){
		
				var itext = new FlxText(0,0,0, "");
				itext.setFormat(Paths.font(""),50, FlxColor.WHITE, CENTER);
				itext.font = songText.font;
				itext.text = songs[curSelected].songName[i];
				itext.ID = i;
		
				if (itext.width > 480)
				{
					itext.scale.x = 480 / itext.width;
					itext.offset.x = 0;
				}
				itext.y = (FlxG.height / 2)-(songs[curSelected].songName.length * 70/2) + 70 * i ;
				itext.x =FlxG.width/4 * 3 - itext.width/2;
				grupoTexto.add(itext);
			}

		}
		else{
			grupoTexto.clear();
		}
	}
	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName[curSong], curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName[curSong], curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = 'Difficulty  '+ CoolUtil.difficultyString();
		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	
		curSelected += change;
		curSong = 0;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
		grupo.forEach(function(spr:FlxSprite)
		{
			FlxTween.tween(spr.offset, {y: 415* curSelected}, 0.2 ,{ease: FlxEase.expoOut, type: FlxTween.ONESHOT});

			if(spr.ID == curSelected){
				FlxTween.tween(spr, {alpha: 1}, 0.1);
				FlxTween.tween(spr.scale, {x: 0.58, y: 0.58}, 0.2, {ease: FlxEase.expoOut});
			}
			else{
				FlxTween.tween(spr, {alpha: 0.8}, 0.1);
				FlxTween.tween(spr.scale, {x: 0.465, y: 0.465}, 0.2, {ease: FlxEase.expoOut});
			}
		});

		grupoImagen.forEach(function(spr:FlxSprite)
		{
			FlxTween.tween(spr.offset, {y: 415* curSelected}, 0.2 ,{ease: FlxEase.expoOut, type: FlxTween.ONESHOT});

			if(spr.ID == curSelected){
				FlxTween.tween(spr, {alpha: 1}, 0.1);
				FlxTween.tween(spr.scale, {x: 0.58, y: 0.58}, 0.2, {ease: FlxEase.expoOut});
			}
			else{
				FlxTween.tween(spr, {alpha: 0.8}, 0.1);
				FlxTween.tween(spr.scale, {x: 0.465, y: 0.465}, 0.2, {ease: FlxEase.expoOut});
			}
		});

		songList(false);
		songList(true);
	}

	function changeSong(change:Int = 0, playSound:Bool = true)
	{
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSong += change;

		if (curSong < 0)
			curSong = songs[curSelected].songName.length - 1;
		if (curSong >= songs[curSelected].songName.length)
			curSong = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName[curSong], curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName[curSong], curDifficulty);
		#end

		grupoTexto.forEach(function(texto:FlxText)
		{
			FlxTween.cancelTweensOf(texto);
			texto.alpha = 1;
			if (texto.ID == curSong)
			{
				FlxTween.tween(texto, {alpha: 0.5}, 0.5, {ease: FlxEase.expoOut, type: FlxTween.PINGPONG});
			}
		});
		
		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
			{
				CoolUtil.difficulties = diffs;
			}
		}
		
		if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}
	}

	private function positionHighscore() {
		songText.x = FlxG.width/2 - songText.width/2;
		diffText.x = FlxG.width/2 - diffText.width/2;
		scoreText.x = diffText.x + diffText.width / 2 - (scoreText.width / 2);
	}
}

class SongMetadata
{
	public var songName:Array<String> = [];
	public var week:Int = 0;
	public var folder:String = "";

	public function new(song:Array<String>, week:Int)
	{
		this.songName = song;
		this.week = week;
		this.folder = Paths.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}
