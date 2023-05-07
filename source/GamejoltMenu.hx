package;

import hxgamejolt.GameJolt as GJClient;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import haxe.Http;
import haxe.io.Bytes;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.ui.FlxUIInputText;
import flash.display.BlendMode;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import MainMenuState;

class GameJoltState extends MusicBeatState
{

	var loginTexts:FlxTypedGroup<FlxText>;
	var loginBoxes:FlxTypedGroup<FlxUIInputText>;
	var loginButtons:FlxTypedGroup<FlxButton>;
	var usernameText:FlxText;
	var tokenText:FlxText;
	var usernameBox:FlxUIInputText;
	var tokenBox:FlxUIInputText;
	var signInBox:FlxButton;
	var helpBox:FlxButton;
	var logOutBox:FlxButton;
	var cancelBox:FlxButton;
	var profileIcon:FlxSprite;
	var username:FlxText;
	var gamename:FlxText;
	var trophy:FlxBar;
	var trophyText:FlxText;
	var missTrophyText:FlxText;

	public static var fromOptions:Bool = false;

	var menuItems:FlxTypedGroup<FlxButton>;

	var icon:FlxSprite;
	var baseX:Int = 370;
	var versionText:FlxText;

	public static var login:Bool = false;

	override function create()
	{

		super.create();

		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('gamejolt/Background', 'preload'));
		bg.setGraphicSize(FlxG.width);
		bg.antialiasing = true;
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

		var bg2:FlxSprite = new FlxSprite().loadGraphic(Paths.image('gamejolt/Background2', 'preload'));
		bg2.setGraphicSize(FlxG.width);
		bg2.antialiasing = true;
		bg2.updateHitbox();
		bg2.screenCenter();
		bg2.scrollFactor.set();
		add(bg2);

		loginTexts = new FlxTypedGroup<FlxText>(2);
		add(loginTexts);

		usernameText = new FlxText(0, 125, 300, "Username:", 30);
		usernameText.alignment = CENTER;

		tokenText = new FlxText(0, 300, 300, "Token:", 30);
		tokenText.alignment = CENTER;

		usernameText.font = "vcr.ttf";
		tokenText.font = "vcr.ttf";

		loginTexts.add(usernameText);
		loginTexts.add(tokenText);
		loginTexts.forEach(function(item:FlxText)
		{
			item.screenCenter(X);
			item.x += baseX;
		});

		loginBoxes = new FlxTypedGroup<FlxUIInputText>(2);
		add(loginBoxes);

		usernameBox = new FlxUIInputText(0, 175, 300, '', 32, FlxColor.BLACK, FlxColor.GRAY);
		usernameBox.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		tokenBox = new FlxUIInputText(0, 350, 300, '', 32, FlxColor.BLACK, FlxColor.GRAY);
		tokenBox.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

		loginBoxes.add(usernameBox);
		loginBoxes.add(tokenBox);
		loginBoxes.forEach(function(item:FlxUIInputText)
		{
			item.screenCenter(X);
			item.x += baseX;
		});
		var loginButton:FlxButton = new FlxButton(usernameBox.x + 75, usernameBox.y + 250, "Login", function()
		{
			GJClient.authUser(usernameBox.text, tokenBox.text, function(json:Dynamic)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				FlxG.save.data.gJLogged = true;
				FlxG.save.data.gJUser = usernameBox.text;
				FlxG.save.data.gJToken = tokenBox.text;

				FlxG.save.flush();
			},
			function(message:String) // on Failure
			{
				FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
				MusicBeatState.switchState(new GameJoltState());
			});
		});

		var backButton:FlxButton = new FlxButton(loginButton.x, loginButton.y + 100, "Back", function()
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
			MusicBeatState.switchState(new MainMenuState());
		});

		FlxG.mouse.visible = false;

		add(backButton);
		add(loginButton);
		backButton.setGraphicSize(150, 50);
		loginButton.setGraphicSize(150, 50);
		loginButton.updateHitbox();
		backButton.updateHitbox();

		if (FlxG.save.data.gJLogged != null) {
			usernameBox.text = FlxG.save.data.gJUser;
			tokenBox.text = FlxG.save.data.gJToken;
		}
	}
}
