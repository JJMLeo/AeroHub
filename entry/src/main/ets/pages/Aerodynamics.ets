import router from '@ohos.router';
import { GasProperties, ResultItem, HistoryItem } from '../utils/GasProperties';

@Entry
@Component
struct Aerodynamics {
  @State altitudeValue: string = '0';
  @State altitudeUnit: string = 'km';
  @State tempType: string = '大气温度';
  @State tempUnit: string = '°C';
  @State tempInput: string = '15';
  @State speedType: string = '表速 (km/h)';
  @State speedValue: string = '0';

  @State results: ResultItem[] = [];
  @State refreshFlag: number = 0;
  @State history: HistoryItem[] = [];
  private lastInputSnapshot: string = '';
  // 防止单位切换时触发onFocus清空
  private preventFocusClear: boolean = false;

  build() {
    Column() {
      // ========== 标题 ==========
      Row() {
        Text('气动计算')
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
          Row() {
            Select([{ value: '高度 (km)' }, { value: '高度 (ft)' }])
              .value(`高度 (${this.altitudeUnit})`)
              .font({ size: 14 })
              .fontColor($r('app.color.primary_text'))
              .selectedOptionFontColor($r('app.color.primary_text'))
              .selectedOptionBgColor($r('app.color.input_bg'))
              .optionFontColor($r('app.color.primary_text'))

              .height(36)
              .borderRadius(4)
              .shadow({ radius: 0 })
              .backgroundColor($r('app.color.input_bg'))
              .flexShrink(0)
              .constraintSize({ minWidth: 100 })
              .onSelect((index: number, value: string) => {
                this.preventFocusClear = true;
                this.altitudeUnit = value.includes('km') ? 'km' : 'ft';
              })
          }
          .width(210)

          TextInput({ text: this.altitudeValue })
            .layoutWeight(1)
            .fontSize(14)
            .height(36)
            .textAlign(TextAlign.End)
            .margin({ left: 12 })
            .backgroundColor($r('app.color.input_bg'))
            .border({ width: 2, color: $r('app.color.accent') })
            .fontColor($r('app.color.primary_text'))
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
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

        // 2. 温度行
        Row() {
          Row() {
            Select([{ value: '大气温度' }, { value: '温度偏差' }])
              .value(this.tempType)
              .font({ size: 14 })
              .fontColor($r('app.color.primary_text'))
              .selectedOptionFontColor($r('app.color.primary_text'))
              .selectedOptionBgColor($r('app.color.input_bg'))
              .optionFontColor($r('app.color.primary_text'))

              .height(36)
              .borderRadius(4)
              .shadow({ radius: 0 })
              .backgroundColor($r('app.color.input_bg'))
              .flexShrink(0)
              .constraintSize({ minWidth: 80 })
              .onSelect((index: number, value: string) => {
                this.preventFocusClear = true;
                this.tempType = value;
              })

            Select([{ value: 'K' }, { value: '°C' }, { value: '°F' }, { value: '°R' }])
              .value(this.tempUnit)
              .font({ size: 14 })
              .fontColor($r('app.color.primary_text'))
              .selectedOptionFontColor($r('app.color.primary_text'))
              .selectedOptionBgColor($r('app.color.input_bg'))
              .optionFontColor($r('app.color.primary_text'))

              .height(36)
              .borderRadius(4)
              .shadow({ radius: 0 })
              .backgroundColor($r('app.color.input_bg'))
              .flexShrink(0)
              .constraintSize({ minWidth: 60 })
              .margin({ left: 8 })
              .onSelect((index: number, value: string) => {
                this.preventFocusClear = true;
                this.tempUnit = value;
              })
          }
          .width(210)

          TextInput({ text: this.tempInput })
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
              this.tempInput = '';
            })
            .onChange((value: string) => { this.tempInput = value; })
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .layoutWeight(1)

        // 3. 速度行
        Row() {
          Row() {
            Select([{ value: '马赫数' }, { value: '表速 (km/h)' }])
              .value(this.speedType)
              .font({ size: 14 })
              .fontColor($r('app.color.primary_text'))
              .selectedOptionFontColor($r('app.color.primary_text'))
              .selectedOptionBgColor($r('app.color.input_bg'))
              .optionFontColor($r('app.color.primary_text'))

              .height(36)
              .borderRadius(4)
              .shadow({ radius: 0 })
              .backgroundColor($r('app.color.input_bg'))
              .flexShrink(0)
              .constraintSize({ minWidth: 110 })
              .onSelect((index: number, value: string) => {
                this.preventFocusClear = true;
                this.speedType = value;
              })
          }
          .width(210)

          TextInput({ text: this.speedValue })
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
              this.speedValue = '';
            })
            .onChange((value: string) => { this.speedValue = value; })
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .layoutWeight(1)

        Button('计算')
          .width('100%')
          .height(40)
          .margin({ top: 8, bottom: 4 })
          .layoutWeight(0.95)
          .onClick(() => { this.calculate(); })
      }
      .padding({ left: 16, right: 16, top: 4, bottom: 4 })
      .backgroundColor($r('app.color.card_bg'))
      .layoutWeight(2)

      // ========== 输出区 ==========
      Column() {
        Divider().strokeWidth(2).color($r('app.color.divider'))
        Scroll() {
          Column() {
            ForEach(this.results,
              (item: ResultItem, index: number) => { this.resultRow(item) },
              (item: ResultItem, index: number) => `${index}-${item.label}-${this.refreshFlag}`
            )
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 4 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
      .backgroundColor($r('app.color.card_bg'))
      .layoutWeight(3)

      // ========== 历史记录区 ==========
      Column() {
        Divider().strokeWidth(2).color($r('app.color.divider'))
        Text('计算历史')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .padding({ left: 16, top: 6, bottom: 4 })
          .backgroundColor($r('app.color.card_bg'))

        if (this.history.length === 0) {
          Text('暂无记录')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding(12)
            .backgroundColor($r('app.color.card_bg'))
        }

        Scroll() {
          Column() {
            ForEach(this.history, (item: HistoryItem, index: number) => {
              Row() {
                Text(`${this.history.length - index}. ${item.resultSummary}`)
                  .fontSize(12)
                  .fontColor($r('app.color.primary_text'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)

                if (item.isISA) {
                  Text('ISA')
                    .fontSize(11)
                    .fontColor($r('app.color.hint_text'))
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
        .constraintSize({ maxHeight: 120 }) // 限制最大高度，显示约4行历史记录
      }
      .layoutWeight(1) // 减少权重，让输入和输出区有更多空间
      .backgroundColor($r('app.color.card_bg'))
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
          .width(160)
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
          .width(80)
          .padding({ left: 4 })
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      Divider().color($r('app.color.divider')).strokeWidth(0.5)
    }
    .width('100%')
  }

  private calculate(): void {
    const altVal = parseFloat(this.altitudeValue);
    const tempVal = parseFloat(this.tempInput);
    const spdVal = parseFloat(this.speedValue);
    if (isNaN(altVal) || isNaN(tempVal) || isNaN(spdVal)) return;

    let altKm = altVal;
    if (this.altitudeUnit === 'ft') altKm = altVal * 0.3048 / 1000;

    const atm = GasProperties.standardAtmosphere(altKm);
    let Ts: number;
    if (this.tempType === '大气温度') {
      Ts = GasProperties.toKelvinAbsolute(tempVal, this.tempUnit);
    } else {
      const deltaK = GasProperties.toKelvinDelta(tempVal, this.tempUnit);
      Ts = atm.Ts + deltaK;
    }
    if (Ts <= 0) return;

    const isStandard = Math.abs(Ts - atm.Ts) < 0.001;

    // ---- 使用多项式计算高温气动特性 ----
    const props = GasProperties.getProps(Ts, 0, GasProperties.Runiv);
    const MW = props.MW;
    const cp = props.cp;
    const cv = props.cv;
    const gamma = props.gamma;
    const R = props.R;
    const hs_abs = props.h;
    const s_psi_abs = props.s_psi;
    
    // 计算参考状态属性 (298.15K, 101325 Pa)
    const T_ref = 298.15;
    const P_ref = 101325;
    const props_ref = GasProperties.getProps(T_ref, 0, GasProperties.Runiv);
    
    // 相对焓和熵函数 (相对于参考状态)
    let hs_ref = props_ref.h;   // 静焓参考基准 [J/kg]
    let s_psi_ref = props_ref.s_psi; // 熵函数参考基准 [J/(kg·K)]

    const a0 = GasProperties.speedOfSound(gamma, R, Ts);   // 声速

    let Ma: number, c: number;
    if (this.speedType === '马赫数') {
      Ma = spdVal;
      c = GasProperties.speedFromMach(Ma, a0);
    } else {
      c = spdVal * 1000 / 3600;
      Ma = GasProperties.machFromSpeed(c, a0);
    }

    const Ps = atm.Ps;
    const rho = GasProperties.density(Ps, R, Ts);
    const bracket = GasProperties.bracket(gamma, Ma);

    // 动压头（可压缩流修正）
    const q = GasProperties.dynamicPressure(rho, c, gamma, Ma);

    const ias = c * 3.6;                 // 表速 km/h

    // 总温（绝热滞止）
    const Tt = GasProperties.totalTemperature(Ts, gamma, Ma);
    // 总焓（绝热能量方程）
    const ht = hs_abs + c * c / 2;

    // 等熵总压、总密度
    const Pt = GasProperties.totalPressure(Ps, gamma, Ma);
    const rhot = GasProperties.totalDensity(rho, gamma, Ma);

    // 马赫角（仅当 Ma > 1）
    const machAngle = GasProperties.machAngle(Ma);

    // 速度系数 λ
    const lambda = GasProperties.velocityCoefficient(gamma, Ma);

    // 绝对熵：s = s0(T) - R·ln(P/101325) （标准压力 1 atm）
    let s_psi = s_psi_abs - s_psi_ref;  // 参考基准绝对熵函数为0
    let s = R * s_psi - R * Math.log(Ps / P_ref);

    // 焓变
    const Dht = ht - hs_ref;
    const Dhs = hs_abs - hs_ref;

    // ---- 组装输出结果 ----
    const formattedResults: ResultItem[] = [
      { label: '大气静压',   value: GasProperties.formatNumber(Ps / 1000, 3),       unit: 'kPa' },
      { label: '大气静温',   value: GasProperties.formatNumber(Ts, 2),              unit: 'K' },
      { label: '大气密度',   value: GasProperties.formatNumber(rho, 6),             unit: 'kg/m³' },
      { label: '声速',       value: GasProperties.formatNumber(a0, 3),              unit: 'm/s' },
      { label: '表速',       value: GasProperties.formatNumber(ias, 3),             unit: 'km/h' },
      { label: '马赫数',     value: GasProperties.formatNumber(Ma, 4),              unit: '' },
      { label: '飞行速度',   value: GasProperties.formatNumber(c*3.6, 3),            unit: 'km/h' },
      { label: '动压',       value: GasProperties.formatNumber(q / 1000, 4),       unit: 'kPa' },
      { label: '总温',       value: GasProperties.formatNumber(Tt, 2),              unit: 'K' },
      { label: '总压',       value: GasProperties.formatNumber(Pt / 1000, 3),       unit: 'kPa' },
      { label: '总密度',     value: GasProperties.formatNumber(rhot, 3),            unit: 'kg/m³' },
      { label: '比焓',       value: GasProperties.formatNumber(hs_abs/1000, 3),     unit: 'kJ/kg' },
      { label: '静焓变',       value: GasProperties.formatNumber(Dhs/1000, 3),              unit: 'kJ/kg' },
      { label: '总焓变',       value: GasProperties.formatNumber(Dht/1000, 3),              unit: 'kJ/kg' },
      { label: '基准焓',       value: GasProperties.formatNumber(hs_ref/1000, 3),              unit: 'kJ/kg' },
      { label: '熵',     value: GasProperties.formatNumber(s, 6),               unit: 'J/(kg·K)' },
      { label: '熵函数',     value: GasProperties.formatNumber(s_psi_abs, 6),               unit: '' },
      { label: '熵函数变',     value: GasProperties.formatNumber(s_psi, 6),               unit: '' },
      { label: '基准熵函数',     value: GasProperties.formatNumber(s_psi_ref, 6),              unit: '' },
      { label: '空气摩尔质量',   value: GasProperties.formatNumber(MW * 1000, 2),           unit: 'g/mol' },
      { label: '定压比热容',   value: GasProperties.formatNumber(cp, 3),              unit: 'J/(kg·K)' },
      { label: '定容比热容',   value: GasProperties.formatNumber(cv, 3),              unit: 'J/(kg·K)' },
      { label: '比热比',     value: GasProperties.formatNumber(gamma, 6),           unit: '' },
      { label: '气体常数',   value: GasProperties.formatNumber(R, 4),              unit: 'J/(kg·K)' },
      { label: '马赫角',     value: isNaN(machAngle) ? '--' : GasProperties.formatNumber(machAngle, 3), unit: '°' },
      { label: '速度系数',   value: GasProperties.formatNumber(lambda, 4),          unit: '' },
      { label: '焓变/熵函数变基准温度',   value: GasProperties.formatNumber(T_ref, 2),               unit: 'K' },
      { label: '焓变/熵函数变基准压力',   value: GasProperties.formatNumber(P_ref/1000, 3),               unit: 'kPa' },
    ];
    this.results = formattedResults;
    this.refreshFlag++;

    // 历史记录
    const currentSnapshot = `${altVal}|${this.altitudeUnit}|${this.tempType}|${tempVal}|${this.tempUnit}|${this.speedType}|${spdVal}`;
    if (currentSnapshot !== this.lastInputSnapshot) {
      const tempC = Ts - 273.15;
      const newEntry: HistoryItem = {
        resultSummary: `Ma=${GasProperties.formatNumber(Ma, 3)}, H=${GasProperties.formatNumber(altKm, 1)}km, T=${GasProperties.formatNumber(tempC, 1)}°C`,
        isISA: isStandard
      };
      this.history = [newEntry, ...this.history].slice(0, 20);
      this.lastInputSnapshot = currentSnapshot;
    }
  }
}