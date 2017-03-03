/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// MotionAndPenPrims.as
// John Maloney, April 2010
//
// Scratch motion and pen primitives.

package primitives {
   import blocks.*;

   import flash.display.*;
   import flash.geom.*;
   import flash.utils.Dictionary;
   import flash.utils.getTimer;

   import interpreter.*;

   import scratch.*;

public class MotionAndPenPrims {

   private var DEGREE_RATIO:Number = 3.2;

   private var app:Scratch;
   private var interp:Interpreter;

   public function MotionAndPenPrims(app:Scratch, interpreter:Interpreter) {
      this.app = app;
      this.interp = interpreter;
   }


   public function addPrimsTo(primTable:Dictionary):void {
      primTable["forward:"]         = primMove;
      primTable["turnRight:"]       = primTurnRight;
      primTable["turnLeft:"]        = primTurnLeft;
      primTable["heading:"]         = primSetDirection;
      primTable["pointTowards:"]    = primPointTowards;
      primTable["gotoX:y:"]         = primGoTo;
      primTable["gotoSpriteOrMouse:"]  = primGoToSpriteOrMouse;
      primTable["glideSecs:toX:y:elapsed:from:"] = primGlide;

      primTable["changeXposBy:"]    = primChangeX;
      primTable["xpos:"]            = primSetX;
      primTable["changeYposBy:"]    = primChangeY;
      primTable["ypos:"]            = primSetY;

      primTable["bounceOffEdge"]    = primBounceOffEdge;

      primTable["xpos"]          = primXPosition;
      primTable["ypos"]          = primYPosition;
      primTable["heading"]       = primDirection;

      primTable["clearPenTrails"]      = primClear;
      primTable["putPenDown"]       = primPenDown;
      primTable["putPenUp"]         = primPenUp;
      primTable["penColor:"]        = primSetPenColor;
      primTable["setPenHueTo:"]     = primSetPenHue;
      primTable["changePenHueBy:"]  = primChangePenHue;
      primTable["setPenShadeTo:"]      = primSetPenShade;
      primTable["changePenShadeBy:"]   = primChangePenShade;
      primTable["penSize:"]         = primSetPenSize;
      primTable["changePenSizeBy:"] = primChangePenSize;
      primTable["stampCostume"]     = primStamp;
      primTable["motorOnFor:elapsed:from:"]   = primTurnMotorOnFor;
      primTable["allMotorsOn"]            = primMotorOn;
      primTable["allMotorsOff"]           = primMotorOff;
      primTable["setRobotDirection:"]         = primRobotDirection;
      primTable["setMotorDirectionAndSpeed:"] = primMotorDirectionAndSpeed;

      primTable["setMotorSpeed:"]         = setMotorSpeed;
      primTable["setMotorSpeedBoth:"]     = setMotorSpeedBoth;
      primTable["setMotionLimit:"]        = setMotionLimit;
      primTable["turnRobotRightDegr:"]    = turnRobotRightDegr;
      primTable["turnRobotLeftDegr:"]     = turnRobotLeftDegr;


      primTable["resetPath"]       = resetPath;
      primTable["clawDegrees"]     = clawDegrees;
      primTable["clawPosition"]    = clawPosition;
   }
   //block for robots


   private function clawDegrees(b:Block):void{
      var degrees:int  = interp.arg(b, 0);
      app.robotCommunicator.setClawDegrees(degrees);
   }
   private function clawPosition(b:Block):void{
      var position:String = interp.arg(b, 0);

      switch(position){
         case "Open":{
            app.robotCommunicator.setClawDegrees(110);
            break;
         }
         case "Half-open":{
            app.robotCommunicator.setClawDegrees(150);
            break;
         }
         case "Closed":{
            app.robotCommunicator.setClawDegrees(220);
            break;
         }
      }
   }



   private function resetPath(b:Block):void{
      app.robotMotorLeft.pathCorrection  = (65536 * app.robotMotorLeft.pathMultiplier)  + app.robotMotorLeft.path;
      app.robotMotorRight.pathCorrection = (65536 * app.robotMotorRight.pathMultiplier) + app.robotMotorRight.path;
   }



   private function setMotorSpeed(b:Block):void {
      app.robotCommunicator.setMotorSpeedNoDirection(check2_100(interp.numarg(b, 0)), check2_100(interp.numarg(b, 0)));
   }

   private function setMotorSpeedBoth(b:Block):void {
      app.robotCommunicator.setMotorSpeedNoDirection(check2_100(interp.numarg(b, 0)), check2_100(interp.numarg(b, 1)));
   }
   private function primMotorDirectionAndSpeed(b:Block):void {

      var directionLeft:String  = interp.arg(b, 0);
      var directionRight:String = interp.arg(b, 1);

      var speedLeft:int  = check2_100(interp.arg(b, 2));
      var speedRight:int = check2_100(interp.arg(b, 3));


      if (interp.activeThread.firstTime) {
         interp.startTimer(0.03);
         interp.redraw();

         if (directionLeft == "forward"){
         }
         else{
            speedLeft = - speedLeft;
         }
         if (directionRight == "forward"){
         }
         else{
            speedRight = - speedRight;
         }
         app.robotCommunicator.setMotorSpeedAndDirection(speedLeft, speedRight);
      }
      else if (interp.checkTimer()){
      }
   }







   private function turnRobotRightDegr(b:Block):void{

      var s:ScratchObj = interp.targetObj();
      if (s == null) return;

      if (interp.activeThread.firstTime){
         app.robotMotorLeft.steps = 0;
         app.robotMotorRight.steps = 0;
         app.robotMotorLeft._steps = 0;
         app.robotMotorRight._steps = 0;
         app.lastTimeMoved = getTimer();
         app.robotEncoderActivated = true;
         app.stepLimit = check0_65535(interp.numarg(b, 0) / DEGREE_RATIO);

         if(app.stepLimit == 0){
            return;
         }

         interp.startTimer(0.10);
         interp.redraw();
         app.robotCommunicator.setMotorSpeedAndLimit(30, -30, app.stepLimit);

      }
      else{
         if(interp.checkTimer()){
            if(app.robotMoveFinished()){
            }
            else{
               interp.startTimer(0.10);
               interp.redraw();
            }
         }
      }
   }
   private function turnRobotLeftDegr(b:Block):void{

      var s:ScratchObj = interp.targetObj();
      if (s == null) return;

      if (interp.activeThread.firstTime){
         app.robotMotorLeft.steps = 0;
         app.robotMotorRight.steps = 0;
         app.robotMotorLeft._steps = 0;
         app.robotMotorRight._steps = 0;
         app.lastTimeMoved = getTimer();
         app.robotEncoderActivated = true;
         app.stepLimit = check0_65535(interp.numarg(b, 0) / DEGREE_RATIO);

         if(app.stepLimit == 0){
            return;
         }

         interp.startTimer(0.10);
         interp.redraw();
         app.robotCommunicator.setMotorSpeedAndLimit(-30, 30, app.stepLimit);

      }
      else{
         if(interp.checkTimer()){
            if(app.robotMoveFinished()){
            }
            else{
               interp.startTimer(0.10);
               interp.redraw();
            }
         }
      }
  }


   private function setMotionLimit(b:Block):void {

      var s:ScratchObj = interp.targetObj();
      if (s == null) return;

      if (interp.activeThread.firstTime){
         app.robotMotorLeft.steps = 0;
         app.robotMotorRight.steps = 0;
         app.robotMotorLeft._steps = 0;
         app.robotMotorRight._steps = 0;
         app.lastTimeMoved = getTimer();
         app.robotEncoderActivated = true;
         app.stepLimit = check0_65535(interp.numarg(b, 0));

         if(app.stepLimit == 0){
            return;
         }


         interp.startTimer(0.10);
         interp.redraw();
         app.robotCommunicator.setMotionLimit(app.stepLimit);

      }
      else{
         if(interp.checkTimer()){
            if(app.robotMoveFinished()){
            }
            else{
               interp.startTimer(0.10);
               interp.redraw();
            }
         }
      }
   }




   private function primTurnMotorOnFor(b:Block):void {

      if(interp.numarg(b, 0) - 0.03 <= 0){
         return;
      }

      if(interp.activeThread.firstTime){
         interp.startTimer(interp.numarg(b, 0) - 0.03);
         interp.redraw();
         app.robotCommunicator.motorOn();
      }
      else if(interp.checkTimer()){
         app.robotCommunicator.motorOff();
      }
   }



   private function primMotorOn(b:Block):void {
      if (interp.activeThread.firstTime) {
         interp.startTimer(0.03);
         interp.redraw();
         app.robotCommunicator.motorOn();
      }
      else if (interp.checkTimer()){
//         app.robotCommunicator.motorOn();
      }
   }

   private function primMotorOff(b:Block):void {
      app.robotEncoderActivated = false;

      if (interp.activeThread.firstTime) {
         interp.startTimer(0.03);
         interp.redraw();
         app.robotCommunicator.motorOff();
      }
      else if (interp.checkTimer()){
//         app.robotCommunicator.motorOff();
      }
   }

   private function primRobotDirection(b:Block):void {
      var direction:String = interp.arg(b, 0);

      if (interp.activeThread.firstTime) {
         interp.startTimer(0.03);
         interp.redraw();

         if (direction == "forward") app.robotCommunicator.goForward();
         else if (direction == "backward") app.robotCommunicator.goBack();
         else if (direction == "turn left") app.robotCommunicator.turnLeft();
         else if (direction == "turn right") app.robotCommunicator.turnRight();
      }
      else if (interp.checkTimer()){
      }
   }





   private function check0_65535(value:int):int{
      if(value > 65535) return 65535;
      if(value < 0)     return 0;
      return value;
   }
   private function check2_100(value:int):int{
      if(value > 100) return 100;
      if(value < 2)   return 2;
      return value;
   }


   //end


   private function primMove(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s == null) return;
      var radians:Number = (Math.PI * (90 - s.direction)) / 180;
      var d:Number = interp.numarg(b, 0);
      moveSpriteTo(s, s.scratchX + (d * Math.cos(radians)), s.scratchY + (d * Math.sin(radians)));
   }

   private function primTurnRight(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s != null) s.setDirection(s.direction + interp.numarg(b, 0));
      if (s.visible) interp.redraw();
   }

   private function primTurnLeft(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s != null) s.setDirection(s.direction - interp.numarg(b, 0));
      if (s.visible) interp.redraw();
   }

   private function primSetDirection(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s != null) s.setDirection(interp.numarg(b, 0));
      if (s.visible) interp.redraw();
   }

   private function primPointTowards(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      var p:Point = mouseOrSpritePosition(interp.arg(b, 0));
      if ((s == null) || (p == null)) return;
      var dx:Number = p.x - s.scratchX;
      var dy:Number = p.y - s.scratchY;
      var angle:Number = 90 - ((Math.atan2(dy, dx) * 180) / Math.PI);
      s.setDirection(angle);
      if (s.visible) interp.redraw();
   }

   private function primGoTo(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s != null) moveSpriteTo(s, interp.numarg(b, 0), interp.numarg(b, 1));
   }

   private function primGoToSpriteOrMouse(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      var p:Point = mouseOrSpritePosition(interp.arg(b, 0));
      if ((s == null) || (p == null)) return;
      moveSpriteTo(s, p.x, p.y);
   }

   private function primGlide(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s == null) return;
      if (interp.activeThread.firstTime) {
         var secs:Number = interp.numarg(b, 0);
         var destX:Number = interp.numarg(b, 1);
         var destY:Number = interp.numarg(b, 2);
         if (secs <= 0) {
            moveSpriteTo(s, destX, destY);
            return;
         }
         // record state: [0]start msecs, [1]duration, [2]startX, [3]startY, [4]endX, [5]endY
         interp.activeThread.tmpObj =
            [interp.currentMSecs, 1000 * secs, s.scratchX, s.scratchY, destX, destY];
         interp.startTimer(secs);
      } else {
         var state:Array = interp.activeThread.tmpObj;
         if (!interp.checkTimer()) {
            // in progress: move to intermediate position along path
            var frac:Number = (interp.currentMSecs - state[0]) / state[1];
            var newX:Number = state[2] + (frac * (state[4] - state[2]));
            var newY:Number = state[3] + (frac * (state[5] - state[3]));
            moveSpriteTo(s, newX, newY);
         } else {
            // finished: move to final position and clear state
            moveSpriteTo(s, state[4], state[5]);
            interp.activeThread.tmpObj = null;
         }
      }
   }

   private function mouseOrSpritePosition(arg:String):Point {
      if (arg == "_mouse_") {
         var w:ScratchStage = app.stagePane;
         return new Point(w.scratchMouseX(), w.scratchMouseY());
      } else {
         var s:ScratchSprite = app.stagePane.spriteNamed(arg);
         if (s == null) return null;
         return new Point(s.scratchX, s.scratchY);
      }
      return null;
   }

   private function primChangeX(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s != null) moveSpriteTo(s, s.scratchX + interp.numarg(b, 0), s.scratchY);
   }

   private function primSetX(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s != null) moveSpriteTo(s, interp.numarg(b, 0), s.scratchY);
   }

   private function primChangeY(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s != null) moveSpriteTo(s, s.scratchX, s.scratchY + interp.numarg(b, 0));
   }

   private function primSetY(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s != null) moveSpriteTo(s, s.scratchX, interp.numarg(b, 0));
   }

   private function primBounceOffEdge(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s == null) return;
      if (!turnAwayFromEdge(s)) return;
      ensureOnStageOnBounce(s);
      if (s.visible) interp.redraw();
   }

   private function primXPosition(b:Block):Number {
      var s:ScratchSprite = interp.targetSprite();
      return (s != null) ? snapToInteger(s.scratchX) : 0;
   }

   private function primYPosition(b:Block):Number {
      var s:ScratchSprite = interp.targetSprite();
      return (s != null) ? snapToInteger(s.scratchY) : 0;
   }

   private function primDirection(b:Block):Number {
      var s:ScratchSprite = interp.targetSprite();
      return (s != null) ? snapToInteger(s.direction) : 0;
   }

   private function snapToInteger(n:Number):Number {
      var rounded:Number = Math.round(n);
      var delta:Number = n - rounded;
      if (delta < 0) delta = -delta;
      return (delta < 1e-9) ? rounded : n;
   }

   private function primClear(b:Block):void {
      app.stagePane.clearPenStrokes();
      interp.redraw();
   }

   private function primPenDown(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s != null) s.penIsDown = true;
      stroke(s, s.scratchX, s.scratchY, s.scratchX + 0.2, s.scratchY + 0.2);
      interp.redraw();
   }

   private function primPenUp(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s != null) s.penIsDown = false;
   }

   private function primSetPenColor(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();

      trace("FUCK=" + interp.numarg(b, 0));

      if (s != null) s.setPenColor(interp.numarg(b, 0));
   }

   private function primSetPenHue(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s != null) s.setPenHue(interp.numarg(b, 0));
   }

   private function primChangePenHue(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s != null) s.setPenHue(s.penHue + interp.numarg(b, 0));
   }

   private function primSetPenShade(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s != null) s.setPenShade(interp.numarg(b, 0));
   }

   private function primChangePenShade(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s != null) s.setPenShade(s.penShade + interp.numarg(b, 0));
   }

   private function primSetPenSize(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s != null) s.setPenSize(Math.max(1, Math.min(960, Math.round(interp.numarg(b, 0)))));
   }

   private function primChangePenSize(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      if (s != null) s.setPenSize(s.penWidth + interp.numarg(b, 0));
   }

   private function primStamp(b:Block):void {
      var s:ScratchSprite = interp.targetSprite();
      // In 3D mode, get the alpha from the ghost filter
      // Otherwise, it can be easily accessed from the color transform.
      var alpha:Number = (Scratch.app.isIn3D ?
         1.0 - (Math.max(0, Math.min(s.filterPack.getFilterSetting('ghost'), 100)) / 100) :
         s.img.transform.colorTransform.alphaMultiplier);

      doStamp(s, alpha);
   }

   private function doStamp(s:ScratchSprite, stampAlpha:Number):void {
      if (s == null) return;
      app.stagePane.stampSprite(s, stampAlpha);
      interp.redraw();
   }

   private function moveSpriteTo(s:ScratchSprite, newX:Number, newY:Number):void {
      if (!(s.parent is ScratchStage)) return; // don't move while being dragged
      var oldX:Number = s.scratchX;
      var oldY:Number = s.scratchY;
      s.setScratchXY(newX, newY);
      s.keepOnStage();
      if (s.penIsDown) stroke(s, oldX, oldY, s.scratchX, s.scratchY);
      if ((s.penIsDown) || (s.visible)) interp.redraw();
   }

   private function stroke(s:ScratchSprite, oldX:Number, oldY:Number, newX:Number, newY:Number):void {
      var g:Graphics = app.stagePane.newPenStrokes.graphics;
      g.lineStyle(s.penWidth, s.penColorCache);
      g.moveTo(240 + oldX, 180 - oldY);
      g.lineTo(240 + newX, 180 - newY);
//trace('pen line('+oldX+', '+oldY+', '+newX+', '+newY+')');
      app.stagePane.penActivity = true;
   }

   private function turnAwayFromEdge(s:ScratchSprite):Boolean {
      // turn away from the nearest edge if it's close enough; otherwise do nothing
      // Note: comparisons are in the stage coordinates, with origin (0, 0)
      // use bounding rect of the sprite to account for costume rotation and scale
      var r:Rectangle = s.getRect(app.stagePane);
      // measure distance to edges
      var d1:Number = Math.max(0, r.left);
      var d2:Number = Math.max(0, r.top);
      var d3:Number = Math.max(0, ScratchObj.STAGEW - r.right);
      var d4:Number = Math.max(0, ScratchObj.STAGEH - r.bottom);
      // find the nearest edge
      var e:int = 0, minDist:Number = 100000;
      if (d1 < minDist) { minDist = d1; e = 1 }
      if (d2 < minDist) { minDist = d2; e = 2 }
      if (d3 < minDist) { minDist = d3; e = 3 }
      if (d4 < minDist) { minDist = d4; e = 4 }
      if (minDist > 0) return false;  // not touching to any edge
      // point away from nearest edge
      var radians:Number = ((90 - s.direction) * Math.PI) / 180;
      var dx:Number = Math.cos(radians);
      var dy:Number = -Math.sin(radians);
      if (e == 1) { dx = Math.max(0.2, Math.abs(dx)) }
      if (e == 2) { dy = Math.max(0.2, Math.abs(dy)) }
      if (e == 3) { dx = 0 - Math.max(0.2, Math.abs(dx)) }
      if (e == 4) { dy = 0 - Math.max(0.2, Math.abs(dy)) }
      var newDir:Number = ((180 * Math.atan2(dy, dx)) / Math.PI) + 90;
      s.setDirection(newDir);
      return true;
   }

   private function ensureOnStageOnBounce(s:ScratchSprite):void {
      var r:Rectangle = s.getRect(app.stagePane);
      if (r.left < 0) moveSpriteTo(s, s.scratchX - r.left, s.scratchY);
      if (r.top < 0) moveSpriteTo(s, s.scratchX, s.scratchY + r.top);
      if (r.right > ScratchObj.STAGEW) {
         moveSpriteTo(s, s.scratchX - (r.right - ScratchObj.STAGEW), s.scratchY);
      }
      if (r.bottom > ScratchObj.STAGEH) {
         moveSpriteTo(s, s.scratchX, s.scratchY + (r.bottom - ScratchObj.STAGEH));
      }
   }

}}
