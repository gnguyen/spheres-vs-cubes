package scripts
{

import org.flixel.*;

import caurina.transitions.*;
import flash.display.BitmapData;
import flash.events.*;
import flash.net.*;
import flash.filters.*;
import stencyl.api.engine.*;
import stencyl.api.engine.actor.*;
import stencyl.api.engine.behavior.*;
import stencyl.api.engine.gui.Label;
import stencyl.api.engine.gui.Panel;
import stencyl.api.data.*;
import stencyl.api.engine.bg.*;
import stencyl.api.engine.font.*;
import stencyl.api.engine.scene.*;
import stencyl.api.engine.sound.*;
import stencyl.api.engine.tile.*;
import stencyl.api.engine.utils.*;


public dynamic class DialogBoxCore extends ActorScript
{
	public var bgImage:BitmapData;
	public var portraitImage:BitmapData;
	public var overflowActor:Actor;
	public var portraitActor:Actor;
	public var bgActorType:ActorType;
	public var overflowActorType:ActorType;
	public var portraitActorType:ActorType;
	public var textList:Array;
	public var currentFont:Font;
	public var keywordFont:Font;

	public var hasOverflow:Boolean;
	public var isDisplaying:Boolean;
	public var isFading:Boolean;
	public var isTyping:Boolean;
	public var playSoundDialog:Boolean;
	public var useBgImage:Boolean;
	public var useFixedSize:Boolean;
	public var useTypingEffect:Boolean;
	
     
	public var fadeTime:Number;
	public var typeDelay:Number;
	public var dialogBoxAlpha:Number;

	public var alignment:int;
	public var bgCornerHeight:int;
	public var bgCornerWidth:int;
	public var currentHeight:int = 150;
	public var currentChar:int;
	public var currentPage:int;
	public var currentWidth:int = 300;
	public var currentXOffset:int;
	public var currentYOffset:int;
	public var fontHeight:int;
	public var numChars:int;
	public var numLines:int;
	public var onChar:int;
	public var overflowXOffset:int;
	public var overflowYOffset:int;
	public var panelHeight:int;
	public var pagesNeeded:int;
	public var portraitXOffset:int;
	public var portraitYOffset:int;
	public var txtBottomMargin:int;
	public var txtLeftMargin:int;
	public var txtRightMargin:int;
	public var txtTopMargin:int;
	public var xPos:int;
	public var yPos:int;

	public var dialogBoxColor:uint;
	
	public var bgPanel:Panel;
	public var txtPanel:Panel;

	public var typingSound:SoundClip;
	public var openSound:SoundClip;
	public var nextSound:SoundClip;
	public var closeSound:SoundClip;

	public var curChar:String;
	public var currentText:String;
	public var defaultText:String;
	public var lines:Array;

	public function DialogBoxCore(actor:Actor, scene:GameState)
	{
		super(actor, scene);
	}
	
	override public function init():void
	{		
	    bringRootPanelToFront();
         bringRootPanelForward(); 
		textList = new Array();     //this will store all of our text

		//make sure we have a default font to work with
		if(currentFont == null) {
			currentFont = Graphics.defaultFont;
		}

		if(keywordFont == null) {
			keywordFont = currentFont;
		}

		currentText = "Default text";
		dialogBoxColor = Util.RGBToHex(0, 0, 0);
		dialogBoxAlpha = 1;
		isDisplaying = false;
		isTyping = false;
		hasOverflow = false;
		pagesNeeded = 1;
		currentPage = 1;  
		bgCornerWidth = 20;
		bgCornerHeight = 20;    

		addWhenUpdatedListener(null, update);
		addWhenDrawingListener(null, draw);     
		//addCollisionListener(actor, handleCollision);                                                      
	}

	//This is where everything happens. It gets called each step of the game.
	public function update(list:Array):void
	{	
		if(txtPanel == null) return;    //we haven't created a panel yet
		
		playSoundDialog = false;
		curChar = null;
		onChar = 0;

		// check to see if we have more text than we can display on one page
		if(isDisplaying && !isTyping && hasOverflow) checkOverflow();

		// remove the overflow indicator if we don't have more text to show
		if(overflowActor != null && (!isDisplaying || isTyping || !hasOverflow))
		{
			overflowActor.die();
			overflowActor = null;
		}

		// remove our portrait actor if the dialog box is no longer displaying
		if(portraitActor !=null && !isDisplaying && !isFading)
		{
			portraitActor.die();
			portraitActor = null;
		}

		// check to see if the characters are typing to the screen, and if so - play the typing sound
	     var displayChar:int = 0;
	     var counter:int = 0;
	     var l2:Label;
	     
		for(var i:int=0; i<txtPanel.getComponents().length; i++)
		{
			l2 = txtPanel.getComponents()[i];
   			numChars = l2.getText().length;
   			onChar = onChar + l2.getNumDisplayChars();
   			if(l2.getNumDisplayChars() > 0) curChar = (l2.getText().charAt(l2.getNumDisplayChars()-1));
   			if(txtPanel.getComponents()[i+1] == null)
   			{
       			if(l2.getNumDisplayChars() == numChars)
       			{
           			isTyping = false;
       			}
    			}
		}

		if(onChar > 0 && onChar != currentChar) 
		{
    			currentChar = onChar;
   			if(!(curChar == " ")) playSoundDialog = true;
		}

		if(typingSound != null && playSoundDialog) typingSound.play();
		if(portraitActor != null)
		{
			if(isTyping) portraitActor.setAnimation("talking");
			else portraitActor.setAnimation("idle");
		}
		
	}
	

	/*
	Main Entry point to display the passed in text.
	*/
	public function requestDialog():void
	{
		if(isFading) return;
		
		// if we already have a dialog box open, handle that separately
		if(isDisplaying) 
		{
			handleOpen();
			return;
		}
	
		//if the user specified a background image, use that and set the dimensions
          if (useBgImage) {
			bgImage = getImageForActorType(bgActorType);
			bgCornerWidth = 20;
			bgCornerHeight = 20;
		     if(useFixedSize)
		     {
		     	currentWidth = bgImage.width;
		     	currentHeight = bgImage.height;
		     }
        	}     
        	else
        	{
			//Create a default image background
			var s:FlxSprite = new FlxSprite(0, 0);
			s.createGraphic(currentWidth,currentHeight,dialogBoxColor,false,null)
			s.solid = false;
			s.antialiasing = true;
			s.frame = 0;
			s.alpha = dialogBoxAlpha;
			bgImage = s._framePixels;
			bgCornerWidth = 1;
			bgCornerHeight = 1;
        	}

	     textList = [];

	     //break up the current section of text into an array of lines
		buildTextList(currentText);
		
		currentText = textList[(textList.length - 1)];     //pop one off the top
		ArrayUtil.removeAt(textList, textList.length-1);   //then remove it

		if(textList.length > 0) hasOverflow = true;        //still more left?
		else hasOverflow = false;
		
		fontHeight = currentFont.getHeight() + (currentFont.getHeight() / 7);
		
        	lines = wordWrap(currentText, currentWidth - txtLeftMargin - txtRightMargin, currentFont);
        	numLines = lines.length;
        	for(var i:int=0; i<lines.length; i++)
        	{
        		print("line " + i + ": " + lines[i]);
        	}

		if(!useBgImage && !useFixedSize) 
		{
			currentHeight = (numLines * fontHeight) + (txtTopMargin + txtBottomMargin) + 5;
			var s:FlxSprite = new FlxSprite(0, 0);
			s.createGraphic(currentWidth,currentHeight,dialogBoxColor,false,null)
			s.solid = false;
			s.antialiasing = true;
			s.frame = 0;
			bgImage = s._framePixels;
		}

		getPosition();

		//create the Panels
		bgPanel = createPanel(xPos + currentXOffset,
		                      yPos + currentYOffset,
		                      currentWidth,
		                      currentHeight);

		txtPanel = createMultilineLabel(currentFont, currentText, txtLeftMargin, txtTopMargin, ((currentWidth - txtLeftMargin) - txtRightMargin));
		bgPanel.setBackground(bgImage, bgCornerWidth, bgCornerHeight);

		if(openSound != null) openSound.play();
		drawDialog();
	}

	public function getPosition():void
	{
		if(alignment == 1) 
		{
			yPos = yPos - currentHeight;
			if(xPos + currentWidth > getScreenWidth())
			{
				xPos = getScreenWidth() - currentWidth;
			}
		}
		if(alignment == 3) xPos = xPos - currentWidth;
		if(alignment == 4) yPos = yPos - currentHeight;
		if(alignment == 5)
		{
			xPos = xPos - currentWidth;
			yPos = yPos - currentHeight;
		}
		if(alignment == 6)
		{
			xPos = xPos - (currentWidth / 2);
			yPos = yPos - (currentHeight / 2);
		}
		
		if(alignment == 7)
		{
			xPos = xPos - (currentWidth / 2);
		}
		
		if(alignment == 8)
		{
			xPos = xPos - (currentWidth / 2);
			yPos = yPos - currentHeight;
		}

	}

	public function drawDialog():void
	{
		if(isFading) return;
		
		if(useTypingEffect)
		{
			typeText();
		}

		//var usePortrait:Boolean = true;
		if(portraitActorType != null)
		{
			createActor(portraitActorType, (xPos + getScreenX() + portraitXOffset + currentXOffset),(yPos + getScreenY() + portraitYOffset + currentYOffset), 1);	
               portraitActor = getLastCreatedActor();
               portraitActor.disableActorDrawing();
		}

		//add the Panel to the Root Panel to display it
		if(!isDisplaying)
		{
			if(fadeTime == 0) fadeTime = getStepSize() / 1000;
			bgPanel.fadeTo(0, 0, "linear",0)
			bgPanel.fadeTo(256, fadeTime*1000, "linear",0)
		}	

		getRootPanel().addComponent(bgPanel);
		bgPanel.addComponent(txtPanel);

		isDisplaying = true;
	}

	public function closeDialog():void
	{
		isFading = true;
		if(fadeTime == 0) fadeTime = getStepSize() / 1000;

		if(closeSound != null) closeSound.play();
		bgPanel.fadeTo(0, fadeTime*1000, "linear",0)
          runLater(1000 * fadeTime, function(timeTask:TimedTask):void {
          		bgPanel.removeComponent(txtPanel);					
           		getRootPanel().removeComponent(bgPanel);
                    isDisplaying = false;
                    hasOverflow = false;
                    isFading = false;
           });
	}
	
	public function handleOpen():void
	{
		if(isTyping)
		{
			endTyping();
			return;
		}

		if(!hasOverflow)
		{
			closeDialog();
			return;
		}

		currentText = textList[textList.length-1];
		ArrayUtil.removeAt(textList, textList.length-1);
	
		if(textList.length < 1) hasOverflow = false;

		bgPanel.removeComponent(txtPanel);
		getRootPanel().removeComponent(bgPanel);
		txtPanel = createMultilineLabel(currentFont, currentText, txtLeftMargin, txtTopMargin, ((currentWidth - txtLeftMargin) - txtRightMargin));

		if(nextSound != null) nextSound.play();
		drawDialog();	
	}

	public function typeText():void
	{
		var l2:Label;
		var delay:int = 250;

		var numChars:int;
		isTyping = true;

		var counter:int = 0;
		for each(var l2:Label in txtPanel.getComponents())
		{
   			numChars = l2.getText().length;
   			l2.setNumDisplayChars(0);
   			l2.animateNumDisplayCharsTo(numChars, numChars * (typeDelay *1000), delay);
   			delay = delay + (numChars * (typeDelay * 1000));
		}
	}

	
	//Stop the typing effect and display the rest of the text
	public function endTyping():void
	{
		var numChars:int = 0;
		isTyping = false;
		var counter:int = 0;
		for each(var l3:Label in txtPanel.getComponents())
		{
			numChars = l3.getText().length;
			l3.setNumDisplayChars(numChars);		
		}
	}

	public function buildTextList(fullText:String):void
	{		
		if(!useFixedSize && !useBgImage)
		{
    			textList.push(fullText);
    			return;
		}

		if(currentFont == null) currentFont = Graphics.defaultFont;
		var height:int = currentFont.getHeight() + (currentFont.getHeight() / 7);
		if((currentHeight-txtTopMargin-txtBottomMargin) < (height + 5)) currentHeight = (height + 5);

		//determine how many lines we can fit within
		//the height restriction
		var linesPerPage:int = ((currentHeight-txtTopMargin-txtBottomMargin) / height);
		var lines:Array = wordWrap(fullText, (currentWidth - txtLeftMargin - txtRightMargin), currentFont);
		var pHeight:int = (lines.length * height) + 5;

		//if our panel height is less than the user
		//defined height, we're OK - quit out.
		if(pHeight < currentHeight-txtTopMargin-txtBottomMargin)
		{
			textList.push(fullText);
			return;
		}

		var counter:int = 0;
		var count:int = 0;
		var index:int=0;
		var text:String = null;
		var tempList:Array = [];
		for(var i:int=0; i<lines.length; i++)
		{
			count++;
			if(text == null) text = lines[i];
			else text = text + " " + lines[i];
			print("text: " + text);
			if(count >= linesPerPage || i == (lines.length-1))
			{
				tempList[counter] = text;
				counter++;
				count=0;
				text = null;
			}
		}

		for(var i:int=tempList.length-1; i>=0; i--)
		{
			textList.push(tempList[i]);
		}
	}

	public function checkOverflow():void
	{
		if(overflowActorType == null) return;
		if(overflowActor == null)
		{
			createActor(overflowActorType, (xPos + getScreenX() + overflowXOffset + currentXOffset + (currentWidth / 2)),(yPos + getScreenY() + overflowYOffset + currentYOffset + currentHeight), 1);	
               overflowActor = getLastCreatedActor();
		}
		
	}

	public function processKeyWords(fullText:String):Array
	{
		var returnText:Array = new Array("","");
		var indexBegin:int = 0;
		var indexEnd:int = 0;
		var spLength:int = 0;
		
		indexBegin = fullText.indexOf("[b]",i);
		if(indexBegin == -1)
		{
			returnText[0] = fullText;
			return returnText;
		}
		
		indexEnd = fullText.indexOf("[/b]",indexBegin);
		if(indexEnd == -1)
		{
			returnText[0] = fullText;
			return returnText;
		}
		
		for(var i:int = 0; i < fullText.length; i++) 
		{
			indexBegin = fullText.indexOf("[b]",i);
			indexEnd = fullText.indexOf("[/b]",indexBegin);
			print("index begin: " + indexBegin);
			print("index end: " + indexEnd);
			if(indexBegin == -1 || indexEnd == -1)
			{
				returnText[0] = returnText[0] + fullText.slice(i,fullText.length);
				for(var x:int = i; x < fullText.length; x++)
				{
					returnText[1] = returnText[1] + "-";
				}
				break;
			}
			
			for(var j:int = i; j < indexBegin; j++)
			{
				returnText[0] = returnText[0] + fullText.charAt(j);
				returnText[1] = returnText[1] + "-";
			}

			indexBegin = indexBegin + 3;
			indexEnd = indexEnd - 1;

			for(var j:int = indexBegin; j < indexEnd+1; j++)
			{
				returnText[0] = returnText[0] + " ";
				returnText[1] = returnText[1] + fullText.charAt(j);
			}

			i = indexEnd + 4;
			
		}
		returnText[1]=fullText;
		print("Exclude Special: " + returnText[0]);
		print("Include Special: " + returnText[1]);
		return returnText;
	}
	//Uncomment this and addCollisionHandler if you want to receive collision events.
	//One event is thrown for each Actor that is collided with.
	/*public void handleCollision(list:Array, event:Collision)
	{
	}*/
	
	//Uncomment this and doesCustomDrawing() if you want to draw graphics. 
	//(0,0) represents the top left corner of the Actor's drawing space.
	public function draw(list:Array, g:Graphics, x:Number, y:Number):void
	{
		if (portraitActor != null && isDisplaying && bgPanel.getOpacity() > 0)
		{		
          	g.translateToScreen();
          	g.setOpacity(Math.min(bgPanel.getOpacity(), 256));
          	g.drawImage(portraitActor.getImage(), (xPos + portraitXOffset + currentXOffset), (yPos + portraitYOffset + currentYOffset));
        	}

	}

}
}