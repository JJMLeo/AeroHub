// 软件主页面 - 功能选择
import router from '@ohos.router';

interface FeatureItem {
  title: string;
  description: string;
  icon: string;
  route: string;
}

@Entry
@Component
struct Main {
  // 功能列表
  private readonly features: FeatureItem[] = [
    {
      title: '气动计算',
      description: '根据高度计算大气参数、飞行参数和热力学参数',
      icon: '📊',
      route: 'pages/Aerodynamics'
    },
    {
      title: '物性参数计算',
      description: '根据温度压力计算热力学参数',
      icon: '⚛️',
      route: 'pages/ThermodynamicProperties'
    },
    {
      title: '标准大气计算', 
      description: '计算标准大气热力学参数',
      icon: '🌡️',
      route: 'pages/StandardAtmosphere'
    },
    {
      title: '单位换算',
      description: '国际标准单位与英制单位换算',
      icon: '🔄',
      route: 'pages/UnitConverter'
    }
  ];

  // 注册自定义花体字
  aboutToAppear() {
    this.getUIContext().getFont().registerFont({
      familyName: 'AeroHubFont',
      familySrc: $rawfile('font/DancingScript-Medium.ttf')
    });
  }

  build() {
    Column() {
      // 应用标题
      Column() {
        Text('AeroHub')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.secondary_text'))
          .fontStyle(FontStyle.Italic)
          .letterSpacing(4)
          .fontFamily('AeroHubFont')
        
        Text('气动计算工具')
          .fontSize(20)
          .fontColor($r('app.color.secondary_text'))
          .margin({ top: 8 })
      }
      .margin({ top: 50, bottom: 40 })

      // 功能网格
      Grid() {
        ForEach(this.features, (item: FeatureItem, index: number) => {
          GridItem() {
            Column() {
              // 图标
              Text(item.icon)
                .fontSize(36)
                .margin({ bottom: 8 })
              
              // 标题
              Text(item.title)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.primary_text'))
                .margin({ bottom: 4 })
              
              // 描述
              Text(item.description)
                .fontSize(12)
                .fontColor($r('app.color.secondary_text'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .textAlign(TextAlign.Center)
                .padding({ left: 8, right: 8 })
            }
            .width('100%')
            .height(140)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(12)
            .shadow({ radius: 8, color: '#00000010' })
            .padding(16)
            .onClick(() => {
              // 跳转到对应页面
              router.pushUrl({
                url: item.route
              }).catch((err: Error) => {
                console.error(`跳转到 ${item.route} 失败:`, err);
              });
            })
          }
        }, (item: FeatureItem, index: number) => index.toString())
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(16)
      .rowsGap(16)
      .width('90%')
      .height('60%')

      // 底部信息
      Column() {
        Text('版本 1.0.2')
          .fontSize(12)
          .fontColor($r('app.color.hint_text'))
          .margin({ bottom: 4 })
        
        Text('航空动力工程计算工具')
          .fontSize(12)
          .fontColor($r('app.color.hint_text'))
          .margin({ bottom: 4 })
        
        Text('© 2026 Aming. All rights reserved.')
          .fontSize(14)
          .fontColor($r('app.color.secondary_text'))
          .fontWeight(FontWeight.Medium)
          .fontStyle(FontStyle.Italic)
          .letterSpacing(0.5)
          .fontFamily('AeroHubFont')
      }
      .margin({ top: 30, bottom: 20 })
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.primary_bg'))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}