// 标准大气计算页面
import router from '@ohos.router';
import { GasProperties, AtmResult, AirProps, ResultItem, HistoryItem } from '../utils/GasProperties';
import { HistoryManager } from '../utils/HistoryManager';


@Entry
@Component
struct StandardAtmosphere {
  @State altitudeValue: string = '0';
  @State altitudeUnit: string = 'km';
  @State unitSystem: string = '国际单位';
  
  @State resultsSI: ResultItem[] = [];  // 国际单位结果
  @State resultsImperial: ResultItem[] = [];  // 英制单位结果
  @State refreshFlag: number = 0;
  @State history: HistoryItem[] = [];
  // 防止单位切换时触发onFocus清空
  private preventFocusClear: boolean = false;

  // 物理常数（标准大气模型参数）
  private readonly g0: number = 9.80665;          // 重力加速度 (m/s²)
  private readonly T0: number = 288.15;           // 海平面温度 (K)
  private readonly P0: number = 101325;           // 海平面压力 (Pa)
  private readonly L: number = -0.0065;           // 温度递减率 (K/m)
  // 其他常数（如气体常数、摩尔质量等）从GasProperties获取

  // 单位转换常数
  private readonly FT_TO_M: number = 0.3048;
  private readonly K_TO_F: number = 1.8;
  private readonly K_TO_R: number = 1.8;
  private readonly PA_TO_PSI: number = 0.000145038;
  private readonly PA_TO_INHG: number = 0.0002953;
  private readonly KG_M3_TO_SLUG_FT3: number = 0.00194032;
  // 热力学单位转换常数
  private readonly JKGK_TO_FTLBFLBR: number = 0.185863;      // J/(kg·K) 到 ft·lbf/(lb·°R)
  private readonly JKGK_TO_BTULBR: number = 0.000238846;    // J/(kg·K) 到 Btu/(lb·°R)
  
  // 页面加载时获取历史记录
  aboutToAppear(): void {
    this.history = HistoryManager.getInstance().getHistory('StandardAtmosphere');
  }

  build() {
    Column() {
      // ========== 标题 ==========
      Row() {
        Text('标准大气计算')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.primary_text'))
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
        
        Button('←')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .width(48)
          .height(48)
          .fontColor($r('app.color.primary_text'))
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            router.back();
          })
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 8, bottom: 8 })
      .backgroundColor($r('app.color.primary_bg'))
      .alignItems(VerticalAlign.Center)

      // ========== 输入区 ==========
      Column() {
        // 1. 高度行
        Row() {
          Text('高度:')
            .fontSize(14)
            .fontColor($r('app.color.primary_text'))
            .width(80)
            .textAlign(TextAlign.End)

          Select([{ value: 'km' }, { value: 'ft' }])
            .value(this.altitudeUnit)
            .font({ size: 14 })
            .fontColor($r('app.color.primary_text'))
            .height(36)
            .borderRadius(4)
            .shadow({ radius: 0 })
            .backgroundColor($r('app.color.input_bg'))
            .layoutWeight(1)
            .margin({ left: 12 })
            .onSelect((index: number, value: string) => {
              this.preventFocusClear = true;
              this.altitudeUnit = value;
            })

          TextInput({ text: this.altitudeValue })
            .layoutWeight(1)
            .fontSize(16)
            .height(36)
            .textAlign(TextAlign.End)
            .margin({ left: 12 })
            .backgroundColor($r('app.color.input_bg'))
            .border({ width: 2, color: $r('app.color.accent') })
            .fontColor($r('app.color.primary_text'))
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .constraintSize({ minWidth: 120 })
            .onFocus(() => {
              if (this.preventFocusClear) {
                this.preventFocusClear = false;
                return;
              }
              this.altitudeValue = '';
            })
            .onChange((value: string) => { this.altitudeValue = value; })
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .layoutWeight(1)

        // 2. 单位系统选择
        Row() {
          Text('单位系统:')
            .fontSize(14)
            .fontColor($r('app.color.primary_text'))
            .width(80)
            .textAlign(TextAlign.End)
          
          Select([{ value: '国际单位' }, { value: '英制单位' }])
            .value(this.unitSystem)
            .font({ size: 14 })
            .fontColor($r('app.color.primary_text'))
            .height(36)
            .borderRadius(4)
            .shadow({ radius: 0 })
            .backgroundColor($r('app.color.input_bg'))
            .layoutWeight(1)
            .margin({ left: 12 })
            .onSelect((index: number, value: string) => {
              this.preventFocusClear = true;
              this.unitSystem = value;
              this.refreshFlag++;
            })
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .layoutWeight(1)

        Button('计算')
          .width('100%')
          .height(40)
          .margin({ top: 8, bottom: 4 })
          .layoutWeight(1)
          .onClick(() => { this.calculate(); })
      }
      .padding({ left: 16, right: 16, top: 4, bottom: 4 })
      .backgroundColor($r('app.color.card_bg'))
      .layoutWeight(1.5)

      // ========== 输出区（弹性高度）==========
      Column() {
        Divider().strokeWidth(2).color($r('app.color.divider'))

        Scroll() {
          Column() {
            if (this.unitSystem === '国际单位') {
              ForEach(this.resultsSI,
                (item: ResultItem, index: number) => { this.resultRow(item) },
                (item: ResultItem, index: number) => `${index}-${item.label}-${item.unit}-${this.refreshFlag}`
              )
            } else {
              ForEach(this.resultsImperial,
                (item: ResultItem, index: number) => { this.resultRow(item) },
                (item: ResultItem, index: number) => `${index}-${item.label}-${item.unit}-${this.refreshFlag}`
              )
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 4 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
      .layoutWeight(4)
      .backgroundColor($r('app.color.card_bg'))

      // ========== 历史记录区 ==========
      Column() {
        Divider().strokeWidth(2).color($r('app.color.divider'))
        Text('计算历史')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.primary_text'))
          .width('100%')
          .padding({ left: 16, top: 6, bottom: 4 })
          .backgroundColor($r('app.color.card_bg'))

        if (this.history.length === 0) {
          Text('暂无记录')
            .fontSize(12)
            .fontColor($r('app.color.hint_text'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding(12)
            .backgroundColor($r('app.color.card_bg'))
        }

        Scroll() {
          Column() {
            ForEach(this.history, (item: HistoryItem, index: number) => {
              Row() {
                Text(`${this.history.length - index}.`)
                  .fontSize(12)
                  .fontColor($r('app.color.primary_text'))
                  .width(24)

                Text(item.resultSummary)
                  .fontSize(12)
                  .fontColor($r('app.color.primary_text'))
                  .fontFamily('monospace') // 使用等宽字体以支持Tab对齐
                  .layoutWeight(1)

                if (item.isISA) {
                  Text('标准大气')
                    .fontSize(11)
                    .fontColor($r('app.color.hint_text'))
                    .width(50)
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 6, bottom: 6 })
              Divider().color($r('app.color.divider')).strokeWidth(0.5)
            }, (item: HistoryItem, index: number) => `${index}-${item.resultSummary}-${item.isISA}`)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
      .layoutWeight(1)
      .backgroundColor($r('app.color.card_bg'))
      .constraintSize({ maxHeight: 120 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  resultRow(item: ResultItem) {
    Column() {
      Row() {
        Text(item.label)
          .fontSize(13)
          .fontColor($r('app.color.primary_text'))
          .width(90)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
        Text(item.value)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.accent'))
          .textAlign(TextAlign.End)
          .maxLines(1)
        Text(item.unit)
          .fontSize(13)
          .fontColor($r('app.color.secondary_text'))
          .width(160)
          .padding({ left: 4 })
          .maxLines(1)
          .textAlign(TextAlign.Start)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      Divider().color($r('app.color.divider')).strokeWidth(0.5)
    }
    .width('100%')
  }

  private formatNumber(num: number, maxDec: number): string {
    let s = num.toFixed(maxDec);
    if (s.indexOf('.') !== -1) {
      s = s.replace(/\.?0+$/, '');
    }
    return s || '0';
  }

  // 转换到英制单位
  private convertToImperial(result: AtmResult): AtmResult {
    // 温度: K -> °F
    const Ts_F = (result.Ts - 273.15) * 9/5 + 32;
    // 压力: Pa -> psi 和 inHg
    const Ps_psi = result.Ps * this.PA_TO_PSI;
    // const Ps_inHg = result.Ps * this.PA_TO_INHG;
    // 密度: kg/m³ -> slug/ft³
    const rho_slug_ft3 = result.rho * this.KG_M3_TO_SLUG_FT3;
    
    return {
      Ts: Ts_F,
      Ps: Ps_psi,  // 返回 psi，但显示时会同时显示两种
      rho: rho_slug_ft3
    };
  }

  private calculate(): void {
    const altVal = parseFloat(this.altitudeValue);
    if (isNaN(altVal)) return;

    // 转换为米
    let altitudeM = altVal;
    if (this.altitudeUnit === 'ft') {
      altitudeM = altVal * this.FT_TO_M;
    } else {
      altitudeM = altVal * 1000;  // km to m
    }

    // 计算标准大气参数
    const resultSI = GasProperties.standardAtmosphere(altitudeM / 1000);
    const resultImperial = this.convertToImperial(resultSI);

    // 获取空气属性（用于计算声速等）
    const airProps = GasProperties.getProps(resultSI.Ts, 0);
    const speedOfSoundSI = GasProperties.speedOfSound(airProps.gamma, airProps.R, resultSI.Ts);
    
    // 英制单位热力学参数
    const MW_g_per_mol = airProps.MW * 1000; // g/mol (单位不变)
    const R_imperial = airProps.R * this.JKGK_TO_FTLBFLBR; // ft·lbf/(lb·°R)
    const cp_imperial = airProps.cp * this.JKGK_TO_BTULBR; // Btu/(lb·°R)
    const cv_imperial = airProps.cv * this.JKGK_TO_BTULBR; // Btu/(lb·°R)

    const resultsSI: ResultItem[] = [
      { label: '静温', value: this.formatNumber(resultSI.Ts, 2), unit: 'K' },
      { label: '  ', value: this.formatNumber(resultSI.Ts - 273.15, 2), unit: '°C' },
      { label: '静压', value: this.formatNumber(resultSI.Ps / 1000, 3), unit: 'kPa' },
      { label: '  ', value: this.formatNumber(resultSI.Ps / 101325, 4), unit: 'atm' },
      { label: '密度', value: this.formatNumber(resultSI.rho, 4), unit: 'kg/m³' },
      { label: '声速', value: this.formatNumber(speedOfSoundSI, 2), unit: 'm/s' },
      { label: '空气摩尔质量', value: this.formatNumber(airProps.MW * 1000, 3), unit: 'g/mol' },
      { label: '气体常数', value: this.formatNumber(airProps.R, 4), unit: 'J/(kg·K)' },
      { label: '定压比热容', value: this.formatNumber(airProps.cp, 2), unit: 'J/(kg·K)' },
      { label: '定容比热容', value: this.formatNumber(airProps.cv, 2), unit: 'J/(kg·K)' },
      { label: '比热比', value: this.formatNumber(airProps.gamma, 5), unit: '' }
    ];

    // 英制单位结果（合并相同标签）
    const resultsImperial: ResultItem[] = [
      { label: '静温', value: this.formatNumber(resultImperial.Ts, 2), unit: '°F' },
      { label: '  ', value: this.formatNumber(resultSI.Ts * 9 / 5, 2), unit: '°R' },
      { label: '静压', value: this.formatNumber(resultImperial.Ps, 4), unit: 'psi' },
      { label: '  ', value: this.formatNumber(resultSI.Ps * this.PA_TO_INHG, 3), unit: 'inHg' },
      { label: '密度', value: this.formatNumber(resultImperial.rho, 5), unit: 'slug/ft³' },
      { label: '声速', value: this.formatNumber(speedOfSoundSI * 3.28084, 2), unit: 'ft/s' },
      { label: '空气摩尔质量', value: this.formatNumber(MW_g_per_mol, 3), unit: 'g/mol' },
      { label: '气体常数', value: this.formatNumber(R_imperial, 5), unit: 'ft·lbf/(lb·°R)' },
      { label: '定压比热容', value: this.formatNumber(cp_imperial, 5), unit: 'Btu/(lb·°R)' },
      { label: '定容比热容', value: this.formatNumber(cv_imperial, 5), unit: 'Btu/(lb·°R)' },
      { label: '比热比', value: this.formatNumber(airProps.gamma, 5), unit: '' }
    ];
    this.resultsSI = resultsSI;
    this.resultsImperial = resultsImperial;
    this.refreshFlag++;

    // 添加到历史记录
    const currentSnapshot = `${altVal}|${this.altitudeUnit}|${this.unitSystem}`;
    const altKm = altitudeM / 1000;
    const newEntry: HistoryItem = {
      resultSummary: `H=${this.formatNumber(altKm, 1)}km\tT=${this.formatNumber(resultSI.Ts - 273.15, 1)}°C\tP=${this.formatNumber(resultSI.Ps / 1000, 1)}kPa`,
      isISA: true
    };
    HistoryManager.getInstance().addHistory('StandardAtmosphere', newEntry, currentSnapshot);
    this.history = HistoryManager.getInstance().getHistory('StandardAtmosphere');
  }
}
