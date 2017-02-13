package ui.parts{
        import flash.display.Shape;
        import flash.display.Sprite;
        import flash.events.MouseEvent;
        import assets.Resources;
        import flash.display.*;
        import uiwidgets.DialogBox;
        import uiwidgets.BlockColorEditor;


        public class DeviceSelector extends Sprite {
                private var icon:Bitmap;
                private var icons:Array = [Resources.createBmp('sensor16_None'),
                                           Resources.createBmp('sensor16_Line'),
                                           Resources.createBmp('sensor16_Led'),
                                           Resources.createBmp('sensor16_Light'),
                                           Resources.createBmp('sensor16_Proximity'),
                                           Resources.createBmp('sensor16_RGB'),
                                           Resources.createBmp('sensor16_Touch'),
                                           Resources.createBmp('sensor16_Ultrasonic'),
                                          ];
                private var iconsHover:Array = [Resources.createBmp('sensor16_None_Hover'),
                                                Resources.createBmp('sensor16_Line_Hover'),
                                                Resources.createBmp('sensor16_Led_Hover'),
                                                Resources.createBmp('sensor16_Light_Hover'),
                                                Resources.createBmp('sensor16_Proximity_Hover'),
                                                Resources.createBmp('sensor16_RGB_Hover'),
                                                Resources.createBmp('sensor16_Touch_Hover'),
                                                Resources.createBmp('sensor16_Ultrasonic_Hover'),
                                               ];
                public var sensor:int;


                public static var dialogBox:DialogBox;

                public function DeviceSelector(sensor:int) {
                   this.sensor = sensor;
                   this.addChild(icons[sensor]);

                   this.buttonMode = true;
                   this.mouseChildren  = false;

                   this.addEventListener(MouseEvent.CLICK, turn);

                   this.addEventListener(MouseEvent.MOUSE_OVER, function():void{
                      while(this.numChildren > 0) this.removeChildAt(0);
                      //this.addChild(iconsHover[sensor]);
                   });

                   this.addEventListener(MouseEvent.MOUSE_OUT, function():void{
                      while(this.numChildren > 0) this.removeChildAt(0);
                      //this.addChild(icons[sensor]);
                   });
                }



                private function turn(e:MouseEvent):void {
                   if(dialogBox == null){
                      dialogBox = new DialogBox();
                      dialogBox.addTitle('Sensor type');
                      dialogBox.addWidget(new DeviceSelectorPanel(this));
                      //dialogBox.addButton('Close', dialogBox.cancel);
                      dialogBox.showOnStage(stage, true);
                   }
                }
        }

}