package;


import flash.display.Sprite;
import flash.display.Bitmap;
import flash.filters.ColorMatrixFilter;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.ui.Keyboard;
import flash.text.TextField;
import flash.Lib;

import openfl.Assets;


import ru.zzzzzzerg.linden.GoogleIAP;
import ru.zzzzzzerg.linden.iap.ProductInfo;
import ru.zzzzzzerg.linden.iap.PurchaseInfo;
import ru.zzzzzzerg.linden.iap.PurchaseHandler;
import ru.zzzzzzerg.linden.iap.ConnectionHandler;

class Main extends Sprite {

    private static var IAP_KEY = "GOOGLE_IN_APP_BILLING_KEY";

    public static var PRODUCT_IDS = [
// test billing product ids
    "android.test.purchased",
    "android.test.canceled",
    "android.test.refunded",
    "android.test.item_unavailable",
// Your app products
    "linden.managed_product"
    ];

    public var googleIAP:GoogleIAP;
    public var created:Bool = false;

    public var purchases:Array<PurchaseInfo> = [];
    public var items:Array<ProductInfo> = [];

    public var purchaseSelected:ColorBtn;
    public var consumeSelected:ColorBtn;
    public var selectNext:ColorBtn;
    public var selectPrev:ColorBtn;
    public var refresh:ColorBtn;
    public var statusLog:TextArea;
    public var resultLog:TextArea;

    var billingIcon:Sprite;

    var selectedProductIdx:Int = 0;

    public function new() {

        super();

        stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);

        purchaseSelected = new ColorBtn(0xCDDB9D, "Purchase\nselected", true).move(20, 10).onClick(onPurchaseSelectedClick);
        consumeSelected = new ColorBtn(0xCDDB9D, "Consume\nselected", true).move(140, 10).onClick(onConsumeSelectedClick);

        selectPrev = new ColorBtn(0xCDDB9D, "Prev", true).move(20, 80).onClick(onPrevClick);
        selectNext = new ColorBtn(0xCDDB9D, "Next", true).move(140, 80).onClick(onNextClick);
        refresh = new ColorBtn(0xCDDB9D, "Refresh", true).move(260, 80).onClick(onRefresh);

        statusLog = new TextArea("", 370, 370).move(20, 150);
        resultLog = new TextArea("", 370, 50).move(20, 530);

        billingIcon = new Sprite();
        billingIcon.addChild(new Bitmap(Assets.getBitmapData("assets/googleplay-64.png")));

        billingIcon.x = 320;
        billingIcon.y = 0;

        addChild(purchaseSelected);
        addChild(consumeSelected);
        addChild(selectPrev);
        addChild(selectNext);
        addChild(refresh);
        addChild(statusLog);
        addChild(resultLog);

        addChild(billingIcon);

        trace("####################################################");
        trace("Start google iap service");
        googleIAP = new GoogleIAP(IAP_KEY, new GoogleIAPHandler(this));
        updateInfo();

//        var scale = Math.min(Lib.current.stage.stageWidth/width,Lib.current.stage.stageHeight/height);
        var scale = Math.min(Lib.current.stage.stageWidth/410,Lib.current.stage.stageHeight/600);
        scaleY = scaleX = scale;
    }

    function onKeyUp(event:KeyboardEvent) {
        switch(event.keyCode)
        {
            case Keyboard.ESCAPE:
                #if sys Lib.exit(); #end
        }
    }

    function onPrevClick(event:MouseEvent) {
        trace("onPrevClick");
        selectedProductIdx = (selectedProductIdx - 1 + PRODUCT_IDS.length) % PRODUCT_IDS.length;
        updateInfo();
    }

    function onNextClick(event:MouseEvent) {
        trace("onNextClick");
        selectedProductIdx = (selectedProductIdx + 1) % PRODUCT_IDS.length;
        updateInfo();
    }

    function onRefresh(event:MouseEvent) {
        trace("onRefresh");
        updateInfo(true);
    }

    function onPurchaseSelectedClick(event:MouseEvent) {
        trace("onPurchaseSelectedClick");
        var productId = PRODUCT_IDS[selectedProductIdx];
        if (!googleIAP.purchaseItem(productId, new IAPPurchaseHandler(this))) {
            resultLog.text.text = 'Can not purchase\nproductId: $productId';
            trace('Can not purchase\nproductId: $productId');
        } else {
            resultLog.text.text ='Purchase productId:$productId';
            trace('Purchase productId: $productId');
        }
    }

    function getActivePurchase(productId):PurchaseInfo {
        for (p in purchases) {
            if (p.productId == productId){
                return  p;
            }
        }
        return null;
    }

    function getItem(productId:String):ProductInfo {
        for (p in items) {
            if (p.productId == productId){
                return  p;
            }
        }
        return null;
    }

    function onConsumeSelectedClick(event:MouseEvent) {
        trace("onConsumeSelectedClick");
        var productId = PRODUCT_IDS[selectedProductIdx];
        var product:PurchaseInfo = getActivePurchase(productId);
        if (product == null) {
            var productId = PRODUCT_IDS[selectedProductIdx];
            resultLog.text.text = 'Purchase "$productId" before';
        } else {
            if (!googleIAP.consumeItem(product.productId, product.purchaseToken)) {
                resultLog.text.text = 'Can not consume\nproductId: ${product.productId}';
                trace('Can not consume\nproductId: ${product.productId}');
            } else {
                resultLog.text.text = 'Consumed\nproductId: ${product.productId}';
                trace('Consumed productId: ${product.productId}');
                updateInfo(true);
            }
        }
    }

    public function onServiceCreated(created:Bool) {
        trace('onServiceCreated: $created');
        this.created = created;
        updateInfo(true);
    }

    public function updateInfo(reloadPurchasse:Bool = false):Void {
        if (created) {
            if (reloadPurchasse) {
                purchases = googleIAP.getPurchases();
                items = googleIAP.getItems(PRODUCT_IDS);
                trace("########3");
                trace(purchases);
                trace(items);
            }
            var ids = purchases.map(function(p) {return p.productId;});
            var items = ['############# productId (count): #############'];
            for (idx in 0...PRODUCT_IDS.length) {
                var productId = PRODUCT_IDS[idx];
                var line = '$productId (${ids.indexOf(productId) == -1 ? 0 : 1}) ${selectedProductIdx==idx? "<<<---[selected]":"" }';
                items.push(line);
            }
            var productId = PRODUCT_IDS[selectedProductIdx];
            items.push('############# product:  #############');
            items.push('${haxe.Json.stringify(getItem(productId))}');
            items.push('############# purchase:  #############');
            items.push('${haxe.Json.stringify(getActivePurchase(productId))}');
            statusLog.text.text = items.join('\n');
        }
        else {
            statusLog.text.text = "BILLING SERVICE IS NOT CREATED";
        }
    }

    public function purchased(item:PurchaseInfo, jsonString:String) {
        trace('onPurchased:\n$jsonString');
        resultLog.text.text = 'Purchased\nproductId: ${item.productId}';
        purchases.push(item);
        updateInfo();
    }

}

class GoogleIAPHandler extends ConnectionHandler {
    var _m:Main;

    public function new(m:Main) {
        super();
        this._m = m;
    }

    override public function onServiceCreated(created:Bool) {
        super.onServiceCreated(created);
        _m.onServiceCreated(created);
    }
}

class IAPPurchaseHandler extends PurchaseHandler {
    var _m:Main;

    public function new(m:Main) {
        super();
        this._m = m;
    }

    override public function purchased(jsonString:String) {
        super.purchased(jsonString);
        _m.purchased(item, jsonString);
    }

    override public function finished() {
        super.finished();
    }
}

class ColorBtn extends Sprite {
    public var enabled:Bool;
    public var label:TextField;
    public var color:Int;

    private static var WIDTH:Int = 64;
    private static var HEIGHT:Int = 64;

    public function new(color:Int, text:String, ?enabled:Bool = true) {
        super();

        this.enabled = enabled;
        this.color = color;
        this.label = new TextField();
        this.label.x = 10;
        this.label.y = HEIGHT / 3.0;
        this.label.text = text;
        this.label.selectable = false;

        addChild(this.label);
        setEnabled(enabled);
    }

    private function fill(clr:Int) {
        graphics.beginFill(clr);
        graphics.drawRect(0, 0, width, HEIGHT);
        graphics.endFill();
    }

    public function setEnabled(e:Bool) {
        this.enabled = e;
        if (this.enabled) {
            fill(color);
            this.useHandCursor = true;
            this.mouseEnabled = true;
        }
        else {
            fill(0xaaaaaa);
            this.useHandCursor = false;
            this.mouseEnabled = false;
        }
    }

    public function move(x, y) {
        this.x = x;
        this.y = y;
        return this;
    }

    public function onClick(handler:MouseEvent -> Void) {
        this.addEventListener(MouseEvent.CLICK, handler);
        return this;
    }
}

class TextArea extends Sprite {
    var _w:Int;
    var _h:Int;

    public var text:TextField;

    public function new(text:String, w:Int, h:Int) {
        super();
        this._w = w;
        this._h = h;

        this.text = new TextField();
        this.text.x = 2;
        this.text.y = 2;
        this.text.width = w;
        this.text.height = h;
        this.text.wordWrap = true;

        addChild(this.text);
        rect(0xff0000);
    }

    public function move(x, y) {
        this.x = x;
        this.y = y;
        return this;
    }

    public function rect(color:Int) {
        graphics.beginFill(0xdddddd);
        graphics.drawRect(0, 0, _w, _h);
        graphics.endFill();
    }
}

