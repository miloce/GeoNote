import { PixArkUIInterface } from "../entity"
import { screenAdapter, toPx, toPy } from "../utils/screenAdapter"


@Component
export struct Component_Ark {
  private getUserPropsById(id: string): PixArkUIInterface | undefined {
          const matches = this.propList?.filter(n => n.componentId === id)
          if (matches.length === 0) {
            return undefined;
          }
          const merged: PixArkUIInterface = {
            componentId: ""
          };
          for (const item of matches) {
            for (const key of Object.keys(item)) {
              Reflect.set(merged, key, Reflect.get(item, key))
            }
          }
          return merged
        }
  private getOverridePropsById(id: string): PixArkUIInterface[] {
          if(!this.propList){
            return [];
          }
          const prefix = new RegExp( `${id}(/)?`);
          const overrideProps = this.propList.filter(prop => prop.pathString?.startsWith(id));
          overrideProps.forEach(n=>n.pathString = n.pathString?.replace(prefix, ""))
          return overrideProps
        }
  @Prop propList: PixArkUIInterface[];
  build() {
    Column() {
      Stack() {
        Image($r('app.media.Vector_27_3843'))
        .height(toPy(64))
        .width(toPx(64))
        .opacity(1)
        .position({ left: toPx(0), top: toPy(0) })
        Image($r('app.media.Vector_27_3844'))
        .height(toPy(9.9))
        .width(toPx(25.57))
        .opacity(1)
        .position({ left: toPx(19.22), top: toPy(38.96) })
        Image($r('app.media.Vector_27_3845'))
        .height(toPy(7.76))
        .width(toPx(7.76))
        .opacity(1)
        .position({ left: toPx(15.71), top: toPy(21.92) })
        Image($r('app.media.Vector_27_3846'))
        .height(toPy(7.76))
        .width(toPx(7.76))
        .opacity(1)
        .position({ left: toPx(40.53), top: toPy(21.92) })
      }
      .visibility(this.getUserPropsById('27:3842')?.visibility ?? Visibility.Visible)
      .width(this.getUserPropsById('27:3842')?.width ?? toPx(64))
      .height(this.getUserPropsById('27:3842')?.height ?? toPy(64))
      .opacity(this.getUserPropsById('27:3842')?.opacity ?? 1)
      .clip(this.getUserPropsById('27:3842')?.clip ?? true)
      .position(this.getUserPropsById('27:3842')?.autoLayoutByParent ?? false ? 
              undefined : {
              top: this.getUserPropsById('27:3842')?.top ?? toPy(0),
              left: this.getUserPropsById('27:3842')?.left ?? toPx(0)
              })
      .zIndex(1)
    }
    .visibility(this.getUserPropsById('27:3841')?.visibility ?? Visibility.Visible)
    .width(this.getUserPropsById('27:3841')?.width ?? toPx(64))
    .height(this.getUserPropsById('27:3841')?.height ?? toPy(64))
    .opacity(this.getUserPropsById('27:3841')?.opacity ?? 1)
    .clip(this.getUserPropsById('27:3841')?.clip ?? true)
    .position(this.getUserPropsById('27:3841')?.autoLayoutByParent ?? false ? 
              undefined : {
              top: this.getUserPropsById('27:3841')?.top ?? toPy(109),
              left: this.getUserPropsById('27:3841')?.left ?? toPx(20)
              })
    .zIndex(1)
    .backgroundColor(this.getUserPropsById('27:3841')?.fillPaints?.[0]?.backgroundColor ?? 'rgba(255, 255, 255, 0)')
  }
  
}