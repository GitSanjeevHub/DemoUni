import { LightningElement, api} from 'lwc';

export default class IconAndTextBar extends LightningElement {

    @api iconName;
    @api iconVariant;
    @api iconSize;

    @api sldsPaddingClass;
    @api sldsTextClass;
    @api sldsBackgroundClass;
    
    get showIcon(){
        return (this.iconName /*&& this.iconName.length > 0*/);
    }

    @api text;

}