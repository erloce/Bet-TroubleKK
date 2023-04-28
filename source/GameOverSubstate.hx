package;

import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxStringUtil;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
#if android
import android.Hardware;
#end

import WiggleEffect;

class GameOverSubstate extends MusicBeatSubstate {
	public var boyfriend:Boyfriend;

	public var camOther:FlxCamera;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;

	var wiggleLose:WiggleEffect;
	var texts:FlxTypedGroup<FlxText>;
	var quoteTexts:FlxTypedGroup<FlxText>;
	var inputText:FlxText;
	var loseSprite:FlxSprite;
	var bfMidPoint:FlxPoint;
	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;
	var closed:Bool = false;

	var quotes:Array<String> = DEFAULT_QUOTES;
	var stageSuffix:String = "";

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';
	public static var vibrationTime:Int = 500; //milliseconds
	public static var quoteMessages:String = '';
	public static var quoteAlignmentX:String = 'left';
	public static var quoteAlignmentY:String = 'bottom';
	public static var loseImageName:String = 'lose';
	public static var loseAlignmentX:String = 'left';
	public static var loseAlignmentY:String = 'top';
	public static var losePosX:Float = 23;
	public static var losePosY:Float = 23;

	public static var instance:GameOverSubstate;

	public static function resetVariables() {
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
		vibrationTime = 500;
		quoteMessages = '';
		quoteAlignmentX = 'left';
		quoteAlignmentY = 'bottom';
		loseImageName = 'lose';
		loseAlignmentX = 'left';
		loseAlignmentY = 'top';
		losePosX = 23;
		losePosY = 23;
	}

	public static function cache() {
		Paths.sound(deathSoundName);
		Paths.music(loopSoundName);
		Paths.music(endSoundName);
		Paths.image(loseImageName);

	override function create() {
		instance = this;
		camOther.zoom = camHUD.zoom = 1;
		camOther.x = camOther.y = camOther.angle = camHUD.x = camHUD.y = camHUD.angle = 0;
		PlayState.instance.callOnLuas('onGameOverStart', []);

		FlxG.sound.play(Paths.sound(deathSoundName));

		super.create();

		var anim = boyfriend.animation.getByName('firstDeath');
		boyfriend.playAnim('firstDeath');
		boyfriend.animation.frameIndex = anim.frames[0];

		new FlxTimer().start(1, function(tmr:FlxTimer) {
			if (closed) return;
			loseSprite.alpha = 1;

			if (loseSprite.animation == null) return;
			var anim = loseSprite.animation.getByName('lose');
			loseSprite.animation.play('lose');
			loseSprite.animation.frameIndex = anim.frames[0];
		});

		doTweenTexts(texts, loseAlignmentY);
		doTweenTexts(quoteTexts, quoteAlignmentY);
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float) {
		super();

		PlayState.instance.setOnLuas('inGameOver', true);
		camOther = PlayState.instance.camOther;
		camHUD = PlayState.instance.camHUD;
		camGame = PlayState.instance.camGame;

		Conductor.songPosition = 0;

		texts = new FlxTypedGroup<FlxText>();
		texts.visible = !ClientPrefs.hideHud;
		texts.cameras = [camHUD];
		add(texts);

		quoteTexts = new FlxTypedGroup<FlxText>();
		quoteTexts.visible = !ClientPrefs.hideHud;
		quoteTexts.cameras = [camHUD];
		add(quoteTexts);

		loseSprite = new FlxSprite(losePosX, losePosY);

		if (ClientPrefs.gameOverInfos) {
			loseSprite.frames = Paths.getSparrowAtlas(loseImageName);
			loseSprite.animation.addByPrefix('lose', 'lose', 24, false);

			var anim = loseSprite.animation.getByName('lose');
			loseSprite.animation.frameIndex = anim.frames[anim.numFrames - 1];
			loseSprite.offset.set(loseSprite.frame.offset.x, loseSprite.frame.offset.y);

			/*
			if (!ClientPrefs.lowQuality) {
				wiggleLose = new WiggleEffect();
				wiggleLose.effectType = HEAT_WAVE_VERTICAL;
				wiggleLose.waveAmplitude = 0.002;
				wiggleLose.waveFrequency = 60;
				wiggleLose.waveSpeed = 4;

				loseSprite.shader = wiggleLose.shader;
			}
			*/

			loseSprite.antialiasing = ClientPrefs.globalAntialiasing;
			loseSprite.cameras = [camHUD];
			loseSprite.alpha = 0.00001;
			add(loseSprite);

			var info:String = "On " + PlayState.SONG.song;

			makeText(PlayState.instance.scoreTxt.text, loseAlignmentX, loseAlignmentY);
			makeText(info, loseAlignmentX, loseAlignmentY);

			inputText = makeText("Press ACCEPT key to Restart | Press BACK key to Quit Gameplay", quoteAlignmentX, quoteAlignmentY, quoteTexts);
			makeText(FlxG.random.getObject(quotes), quoteAlignmentX, quoteAlignmentY, quoteTexts);
		}

		boyfriend = new Boyfriend(x, y, characterName);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);

		bfMidPoint = boyfriend.getGraphicMidpoint();

		#if android
		if(ClientPrefs.vibration)
		{
			Hardware.vibrate(vibrationTime);
		}
		#end

		camFollow = new FlxPoint(bfMidPoint.x, bfMidPoint.y);

		Conductor.changeBPM(100);
		camGame.scroll.set();
		camGame.target = null;

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(camGame.scroll.x + (camGame.width / 2), camGame.scroll.y + (camGame.height / 2));
		add(camFollowPos);

		#if android
		addVirtualPad(NONE, A_B);
		addPadCamera();
		#end
	}

	function makeText(str:String, alignX:String, alignY:String, ?grp:FlxTypedGroup<FlxText>):FlxText {
		var isLeft:Bool = alignX != 'right';
		var isTop:Bool = alignY != 'bottom';

		var width:Float = FlxG.width - 46;
		var height:Float = 18;
		var x:Float = 0;
		var y:Float = 0;

		if (grp != null) {
			x = 23;
			if (grp.length > 0)
				y = grp.members[grp.length - 1].y + (isTop ? height + 7 : -height + 6);
			else
				y = isTop ? 23 : FlxG.height - height - 23;
		}
		else {
			x = isLeft ? loseSprite.x : loseSprite.x + loseSprite.width - width;
			if (texts.length > 0)
				y = texts.members[texts.length - 1].y + (isTop ? height + 7 : -height + 6);
			else
				y = loseSprite.y - loseSprite.offset.y + (isTop ? loseSprite.height + 8 : -8);
		}

		var text:FlxText = new FlxText(x, y - 8, width, str, Std.int(height));
		text.setFormat(Paths.font("vcr.ttf"), Std.int(height), FlxColor.WHITE, isLeft ? LEFT : RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.antialiasing = ClientPrefs.globalAntialiasing;
		text.borderSize = 1.25;
		text.alpha = 0;

		if (grp != null) grp.add(text);
		else texts.add(text);
		return text;
	}

	function doTweenTexts(grp:FlxTypedGroup<FlxText>, alignY:String):Void {
		if (grp == null || grp.members.length <= 0) return;
		var isTop:Bool = alignY != 'bottom';

		var delay:Float = 1.3 + (isTop ? 0 : grp.members.length * .2);
		for (text in grp.members) {
			FlxTween.tween(text, {y: text.y + 8, alpha: 1}, 1,
				{ease: FlxEase.quadOut, startDelay: delay}
			);
			delay += isTop ? .2 : -.2;
		}
	}

	var isFollowingAlready:Bool = false;
	override function update(elapsed:Float) {
		super.update(elapsed);

		if (wiggleLose != null) wiggleLose.update(elapsed);

		PlayState.instance.callOnLuas('onUpdate', [elapsed]);
		if (updateCamera) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (controls.ACCEPT) {
			endBullshit();
		}

		if (controls.BACK) {
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.chartingMode = false;

			WeekData.loadTheFirstEnabledMod();
			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.instance.callOnLuas('onGameOverConfirm', [false]);
		}

		if (!isEnding && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name == 'firstDeath') {
			if(boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready) {
				camGame.follow(camFollowPos, LOCKON, 1);
				updateCamera = true;
				isFollowingAlready = true;
			}

			if (boyfriend.animation.curAnim.finished && !playingDeathSound) {
				if (PlayState.SONG.stage == 'tank') {
					coolStartDeath(0.2);
					
					var exclude:Array<Int> = [];
					//if(!ClientPrefs.cursing) exclude = [1, 3, 8, 13, 17, 21];

					FlxG.sound.play(Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, exclude)), 1, false, null, true, function() {
						if(!isEnding) FlxG.sound.music.fadeIn(0.2, 1, 4);
					});
				}
				else {
					coolStartDeath();
				}
				playingDeathSound = boyfriend.startedDeath = true;
			}
		}

		if (FlxG.sound.music.playing) {
			Conductor.songPosition = FlxG.sound.music.time;
		}
		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
	}

	override function beatHit() {
		super.beatHit();

		//FlxG.log.add('beat');
	}

	override function destroy() {
		closed = true;
		super.destroy();
	}

	var isEnding:Bool = false;
	var endCompleted:Bool = false;
	var quick:Bool = false;
	var slowass:FlxTimer;

	function resetState():Void {
		if (slowass != null) slowass.cancel();
		FlxTransitionableState.skipNextTransIn = true;
		MusicBeatState.resetState();
	}

	function coolStartDeath(?volume:Float = 1):Void {
		FlxG.sound.playMusic(Paths.music(loopSoundName), volume);
	}

	function endSoundComplete():Void {
		if (endCompleted) {
			resetState();
			return;
		}
		endCompleted = true;
	}

	function endBullshit():Void {
		if (isEnding) {
			quick = true;
			if (endCompleted) {
				resetState();
			}
			return;
		}
		isEnding = true;

		inputText.text = 'Restarting...';
		boyfriend.playAnim('deathConfirm', true);
		FlxG.sound.music.stop();

		var snd:FlxSound = FlxG.sound.play(Paths.music(endSoundName));
		snd.onComplete = endSoundComplete;

		new FlxTimer().start(0.7, function(tmr:FlxTimer) {
			camOther.fade(FlxColor.BLACK, if (quick) 1 else 2, false, function() {
				if (quick || endCompleted) {
					resetState();
				}
				endCompleted = true;

				if (!quick) {
					slowass = new FlxTimer().start(1.3, function(tmr:FlxTimer) {
						resetState();
						return;
					});
				}
			});
		});

		PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
	}

	private function getBoyfriend(x:Float, y:Float):Boyfriend {
		var ins:PlayState = PlayState.instance;

		var bf = ins.boyfriendMap.get(characterName);
		if (bf != null) {
			bf.setPosition(x, y);
			bf.alpha = 1;
			return bf;
		}

		return new Boyfriend(x, y, characterName);
	}

	private static var DEFAULT_QUOTES:Array<String> = [
		"You need to get basics right first or you'll end up like this again",
		"Maybe if you aren't bad enough, you wouldn't be here",
		"Hit the notes precisely to not lose... Dumbass",
		"skill issue lmfao",
		//discord/shrimpsketti#7483
		"Press the notes to get points",
		//github/WheresHappy
		"My grandma can play better than you",
		"No fingers?",
		//discord/Unholywanderer04#1468
		"guh",
		//github/probablynotbetopia
		"The notes keep you alive, why are you afraid of them they're not gonna kill you or anything",
		//Erlicer :v
		"Are you an unstudied species?",
		"That's not what your mother said yesterday.",
		"HAH, you died",
		"Try to hit the notes next time",
		"I wonder if your girlfriend was bought or if she's just as stupid as you",
		"You should look for a therapist",
		"Are you a streamer? Is it just showing death screens? If so, please stop. It's scary.",
		"2 + 2 = you're dumb",
		"Is this intentional?",
		"PRESS THE FUCKIN NOTES YOU STUPID",
		"Are you trying to get an achievement?",
		"You're embarrassing yourself in front of your viewers",
		"gay",
		"I think you died. Just a guess"
		"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
	];
}
